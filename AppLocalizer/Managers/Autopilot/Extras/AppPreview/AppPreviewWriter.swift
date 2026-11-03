//
//  AppPreviewWriter.swift
//  AppLocalizer
//

import AudioToolbox
import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation

/// Writes the App Preview movie: H.264 High Profile Level 4.0 (what Apple
/// asks for) at the spec's size and a constant frame rate, in a QuickTime
/// file, with a stereo AAC sound track as long as the video: the music
/// (`AppPreviewSoundtrack`), or silence without one, since App Store
/// Connect wants a stereo sound track either way. Frames are drawn
/// straight into the encoder's pixel buffers. Both tracks are fed from the
/// one task, without waiting on either: the sound stays half a second
/// ahead of the video, so the writer can always interleave the two. Used
/// by one task at a time.
final class AppPreviewWriter {
    /// The number of frames written so far.
    private(set) var frameCount = 0

    private let writer: AVAssetWriter
    private let pixels: AVAssetWriterInput.PixelBufferReceiver
    private let sound: AVAssetWriterInput.SampleBufferReceiver
    private let spec: AppPreviewSpec
    private let colorSpace: CGColorSpace
    /// The music; nil writes silence.
    private let soundtrack: AppPreviewSoundtrack?
    /// Audio sample frames written so far.
    private var audioFrames: Int64 = 0

    static let sampleRate = 44100
    /// Audio sample frames per buffer of sound.
    static let audioChunk = 1024
    /// How far the sound runs ahead of the video.
    static let audioLead = 0.5
    /// Apple's App Preview audio: 256 kbps AAC.
    static let audioBitRate = 256_000

    init(output: URL, spec: AppPreviewSpec, bitRate: Int, soundtrack: AppPreviewSoundtrack? = nil) throws {
        self.spec = spec
        self.soundtrack = soundtrack
        try? FileManager.default.removeItem(at: output)
        do {
            writer = try AVAssetWriter(outputURL: output, fileType: .mov)
        } catch {
            throw AppPreviewError.writerFailed(error.localizedDescription)
        }
        let video = AVAssetWriterInput(mediaType: .video, outputSettings: Self.videoSettings(spec: spec, bitRate: bitRate))
        let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: Self.sampleRate,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: Self.audioBitRate,
        ])
        guard writer.canAdd(video), writer.canAdd(audio), Self.soundFormat() != nil, let space = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw AppPreviewError.writerFailed(String(localized: "The movie's tracks couldn't be set up."))
        }
        colorSpace = space
        pixels = writer.inputPixelBufferReceiver(for: video, pixelBufferAttributes: Self.pixelAttributes(spec: spec))
        sound = writer.inputReceiver(for: audio)
        do {
            try writer.start()
        } catch {
            throw AppPreviewError.writerFailed(error.localizedDescription)
        }
        writer.startSession(atSourceTime: .zero)
    }

    /// The time of the next frame, in seconds.
    var nextFrameSeconds: Double { Double(frameCount) / Double(max(spec.framesPerSecond, 1)) }

    /// Draws the next frame with `draw`, in a context of the spec's size
    /// with Core Graphics' bottom-left origin, and appends it. With
    /// `keepingImage` it also returns what was drawn.
    @discardableResult
    func appendFrame(keepingImage: Bool = false, draw: (CGContext) throws -> Void) async throws -> CGImage? {
        try Task.checkCancellation()
        var buffer = try pixelBuffer()
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let size = spec.pixelSize
        let space = colorSpace
        let image = try buffer.accessUnsafeMutableRawPlaneBytes { planes -> CGImage? in
            guard let plane = planes.first, let context = CGContext(
                data: plane.bytes.baseAddress, width: size.width, height: size.height, bitsPerComponent: 8,
                bytesPerRow: plane.properties.bytesPerRow, space: space, bitmapInfo: info
            ) else { throw AppPreviewError.drawingFailed }
            context.interpolationQuality = .high
            try draw(context)
            return keepingImage ? context.makeImage() : nil
        }
        let frame = CVReadOnlyPixelBuffer(buffer)
        let time = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(max(spec.framesPerSecond, 1)))
        while try !pixels.appendImmediately(frame, with: time) {
            try Task.checkCancellation()
            try checkWriter()
            try appendSound(upTo: nextFrameSeconds + Self.audioLead + 1)
            try await Task.sleep(for: .milliseconds(2))
        }
        frameCount += 1
        try appendSound(upTo: nextFrameSeconds + Self.audioLead)
        return image
    }

    /// Writes the rest of the sound and closes the file, ending the
    /// session with the last frame so the sound that ran ahead is cut and
    /// the movie is exactly as long as its video.
    func finish() async throws {
        let end = nextFrameSeconds
        pixels.finish()
        while audioSeconds < end - 0.000_1 {
            try Task.checkCancellation()
            try checkWriter()
            let before = audioFrames
            try appendSound(upTo: end)
            if audioFrames == before { try await Task.sleep(for: .milliseconds(2)) }
        }
        sound.finish()
        writer.endSession(atSourceTime: CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(max(spec.framesPerSecond, 1))))
        await writer.finishWriting()
        guard writer.status == .completed else { throw AppPreviewError.writerFailed(Self.reason(writer.error)) }
    }

    /// Stops writing; the caller deletes the file.
    func cancel() {
        if writer.status == .writing { writer.cancelWriting() }
    }

    // MARK: - Video

    private func pixelBuffer() throws -> CVMutablePixelBuffer {
        do {
            if let pool = pixels.pixelBufferPool { return try pool.makeMutablePixelBuffer() }
            return try CVMutablePixelBuffer(Self.pixelAttributes(spec: spec))
        } catch {
            throw AppPreviewError.drawingFailed
        }
    }

    private func checkWriter() throws {
        if writer.status == .failed || writer.status == .cancelled { throw AppPreviewError.writerFailed(Self.reason(writer.error)) }
    }

    private static func pixelAttributes(spec: AppPreviewSpec) -> CVPixelBufferCreationAttributes {
        CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
            size: CVImageSize(width: spec.pixelSize.width, height: spec.pixelSize.height),
            compatibility: [.cgBitmapContext, .cgImage]
        )
    }

    private static func videoSettings(spec: AppPreviewSpec, bitRate: Int) -> [String: Any] {
        [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: spec.pixelSize.width,
            AVVideoHeightKey: spec.pixelSize.height,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ],
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitRate,
                AVVideoExpectedSourceFrameRateKey: spec.framesPerSecond,
                AVVideoMaxKeyFrameIntervalKey: spec.framesPerSecond,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                AVVideoAllowFrameReorderingKey: false,
            ],
        ]
    }

    // MARK: - Sound

    private var audioSeconds: Double { Double(audioFrames) / Double(Self.sampleRate) }

    /// Appends the sound up to `seconds`, stopping early when the audio
    /// input isn't ready for more.
    private func appendSound(upTo seconds: Double) throws {
        let limit = Int64((seconds * Double(Self.sampleRate)).rounded())
        while audioFrames < limit {
            let count = Int(min(Int64(Self.audioChunk), limit - audioFrames))
            let buffer = try Self.soundBuffer(frames: count, at: audioFrames, from: soundtrack)
            guard try sound.appendImmediately(CMReadySampleBuffer<CMSampleBuffer.DynamicContent>(unsafeBuffer: buffer)) else { return }
            audioFrames += Int64(count)
        }
    }

    /// `frames` stereo 16-bit frames of the soundtrack (zeros without
    /// one), starting at sample `start`. Everything is made here, so the
    /// buffer belongs to no one else.
    private static func soundBuffer(frames: Int, at start: Int64, from soundtrack: AppPreviewSoundtrack?) throws -> CMSampleBuffer {
        let failure = AppPreviewError.writerFailed(String(localized: "The sound track couldn't be made."))
        guard let format = soundFormat() else { throw failure }
        let bytes = frames * 4
        var block: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: bytes, blockAllocator: kCFAllocatorDefault, customBlockSource: nil,
            offsetToData: 0, dataLength: bytes, flags: kCMBlockBufferAssureMemoryNowFlag, blockBufferOut: &block
        )
        guard status == noErr, let block else { throw failure }
        status = CMBlockBufferFillDataBytes(with: 0, blockBuffer: block, offsetIntoDestination: 0, dataLength: bytes)
        if status == noErr, let soundtrack {
            var pointer: UnsafeMutablePointer<CChar>?
            status = CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: nil, dataPointerOut: &pointer)
            if status == noErr, let pointer { soundtrack.copy(frames: frames, from: start, into: UnsafeMutableRawPointer(pointer)) }
        }
        var sample: CMSampleBuffer?
        if status == noErr {
            status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
                allocator: kCFAllocatorDefault, dataBuffer: block, formatDescription: format, sampleCount: frames,
                presentationTimeStamp: CMTime(value: start, timescale: CMTimeScale(sampleRate)), packetDescriptions: nil, sampleBufferOut: &sample
            )
        }
        guard status == noErr, let sample else { throw failure }
        return sample
    }

    private static func soundFormat() -> CMAudioFormatDescription? {
        var description = AudioStreamBasicDescription(
            mSampleRate: Double(sampleRate), mFormatID: kAudioFormatLinearPCM, mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 2, mBitsPerChannel: 16, mReserved: 0
        )
        var format: CMAudioFormatDescription?
        let status = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault, asbd: &description, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil,
            formatDescriptionOut: &format
        )
        return status == noErr ? format : nil
    }

    private static func reason(_ error: (any Error)?) -> String {
        error?.localizedDescription ?? String(localized: "The movie writer gave no reason.")
    }
}
