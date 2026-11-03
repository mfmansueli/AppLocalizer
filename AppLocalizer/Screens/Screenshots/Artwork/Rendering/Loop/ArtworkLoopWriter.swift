//
//  ArtworkLoopWriter.swift
//  AppLocalizer
//

import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation

/// Writes a header or search motion loop: a silent QuickTime movie (search
/// results can't unmute) at the artwork's size and 30 fps, H.264, or HEVC
/// when the encoder doesn't take H.264 at that size. Frames are drawn
/// straight into the encoder's pixel buffers. Used by one task at a time.
final class ArtworkLoopWriter {
    private(set) var frameCount = 0
    /// "H.264" or "HEVC".
    let codecTitle: String

    private let writer: AVAssetWriter
    private let pixels: AVAssetWriterInput.PixelBufferReceiver
    private let size: PixelSize
    private let framesPerSecond: Int
    private let colorSpace: CGColorSpace

    /// About 24 Mbps at 3840 × 2560: a slow, soft loop needs little more.
    static func bitRate(for size: PixelSize) -> Int {
        max(8_000_000, size.width * size.height * 5 / 2)
    }

    init(output: URL, size: PixelSize, framesPerSecond: Int) throws {
        self.size = size
        self.framesPerSecond = framesPerSecond
        try? FileManager.default.removeItem(at: output)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { throw ArtworkLoopError.writerFailed("No sRGB color space.") }
        colorSpace = space
        var made: (AVAssetWriter, AVAssetWriterInput, String)?
        for codec in [AVVideoCodecType.h264, .hevc] {
            guard let candidate = try? AVAssetWriter(outputURL: output, fileType: .mov) else { continue }
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: Self.videoSettings(codec: codec, size: size, framesPerSecond: framesPerSecond))
            input.expectsMediaDataInRealTime = false
            if candidate.canAdd(input) {
                made = (candidate, input, codec == .h264 ? "H.264" : "HEVC")
                break
            }
        }
        guard let (writer, input, title) = made else { throw ArtworkLoopError.writerFailed(String(localized: "The movie couldn't be set up.")) }
        self.writer = writer
        codecTitle = title
        pixels = writer.inputPixelBufferReceiver(for: input, pixelBufferAttributes: CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
            size: CVImageSize(width: size.width, height: size.height),
            compatibility: [.cgBitmapContext, .cgImage]
        ))
        do {
            try writer.start()
        } catch {
            throw ArtworkLoopError.writerFailed(error.localizedDescription)
        }
        writer.startSession(atSourceTime: .zero)
    }

    /// Draws the next frame with `draw`, in a context of the artwork's size
    /// with Core Graphics' bottom-left origin, and appends it.
    func appendFrame(draw: (CGContext) -> Void) async throws {
        try Task.checkCancellation()
        var buffer: CVMutablePixelBuffer
        do {
            if let pool = pixels.pixelBufferPool {
                buffer = try pool.makeMutablePixelBuffer()
            } else {
                buffer = try CVMutablePixelBuffer(CVPixelBufferCreationAttributes(
                    pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
                    size: CVImageSize(width: size.width, height: size.height), compatibility: [.cgBitmapContext, .cgImage]
                ))
            }
        } catch {
            throw ArtworkLoopError.drawingFailed
        }
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let size = size
        let space = colorSpace
        try buffer.accessUnsafeMutableRawPlaneBytes { planes in
            guard let plane = planes.first, let context = CGContext(
                data: plane.bytes.baseAddress, width: size.width, height: size.height, bitsPerComponent: 8,
                bytesPerRow: plane.properties.bytesPerRow, space: space, bitmapInfo: info
            ) else { throw ArtworkLoopError.drawingFailed }
            context.interpolationQuality = .high
            draw(context)
        }
        let frame = CVReadOnlyPixelBuffer(buffer)
        let time = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(framesPerSecond))
        while try !pixels.appendImmediately(frame, with: time) {
            try Task.checkCancellation()
            try checkWriter()
            try await Task.sleep(for: .milliseconds(2))
        }
        frameCount += 1
    }

    /// Closes the file, ending with the last frame.
    func finish() async throws {
        pixels.finish()
        writer.endSession(atSourceTime: CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(framesPerSecond)))
        await writer.finishWriting()
        guard writer.status == .completed else { throw ArtworkLoopError.writerFailed(writer.error?.localizedDescription ?? "") }
    }

    func cancel() {
        if writer.status == .writing { writer.cancelWriting() }
    }

    private func checkWriter() throws {
        if writer.status == .failed || writer.status == .cancelled {
            throw ArtworkLoopError.writerFailed(writer.error?.localizedDescription ?? "")
        }
    }

    private static func videoSettings(codec: AVVideoCodecType, size: PixelSize, framesPerSecond: Int) -> [String: Any] {
        var compression: [String: Any] = [
            AVVideoAverageBitRateKey: bitRate(for: size),
            AVVideoExpectedSourceFrameRateKey: framesPerSecond,
            AVVideoMaxKeyFrameIntervalKey: framesPerSecond,
            AVVideoAllowFrameReorderingKey: false,
        ]
        if codec == .h264 { compression[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel }
        return [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ],
            AVVideoCompressionPropertiesKey: compression,
        ]
    }
}
