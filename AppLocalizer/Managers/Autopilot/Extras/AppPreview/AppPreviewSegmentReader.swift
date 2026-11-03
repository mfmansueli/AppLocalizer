//
//  AppPreviewSegmentReader.swift
//  AppLocalizer
//

import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation
import VideoToolbox

/// Reads one segment's stretch of the Simulator recording and answers which
/// of its images shows at a given moment: the last one that started at or
/// before it. Simulator recordings only add a frame when the screen
/// changes, so one image can last for seconds. Times must not go back.
/// Used by one task at a time.
final class AppPreviewSegmentReader {
    private typealias Sample = CMReadySampleBuffer<CMSampleBuffer.DynamicContent>

    private let reader: AVAssetReader
    private let provider: AVAssetReaderOutput.Provider<Sample>
    private var started = false
    /// The next image, not shown yet, and when it starts.
    private var pending: (buffer: CVReadOnlyPixelBuffer, seconds: Double)?
    /// The image showing now.
    private var current: CVReadOnlyPixelBuffer?
    private var currentImage: CGImage?

    init(asset: AVAsset, track: AVAssetTrack, segment: AppPreviewSegment) throws {
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw AppPreviewError.readerFailed(error.localizedDescription)
        }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.timeRange = CMTimeRange(
            start: CMTime(seconds: segment.start, preferredTimescale: 600), duration: CMTime(seconds: segment.duration + 0.5, preferredTimescale: 600)
        )
        guard reader.canAdd(output) else { throw AppPreviewError.readerFailed(String(localized: "Its video can't be decoded.")) }
        provider = reader.outputProvider(for: output)
        do {
            try reader.start()
        } catch {
            throw AppPreviewError.readerFailed(error.localizedDescription)
        }
    }

    /// The image showing `seconds` into the recording, or nil when the
    /// segment's stretch holds no image at all.
    func image(at seconds: Double) async throws -> CGImage? {
        if !started {
            started = true
            pending = try await nextImage()
        }
        while let next = pending, next.seconds <= seconds + 0.000_5 {
            try await show(next.buffer)
        }
        if current == nil, let next = pending {
            try await show(next.buffer)
        }
        guard let current else { return nil }
        if currentImage == nil {
            currentImage = current.withUnsafeBuffer { buffer -> CGImage? in
                var image: CGImage?
                VTCreateCGImageFromCVPixelBuffer(buffer, options: nil, imageOut: &image)
                return image
            }
        }
        return currentImage
    }

    func cancel() {
        if reader.status == .reading { reader.cancelReading() }
    }

    private func show(_ buffer: CVReadOnlyPixelBuffer) async throws {
        current = buffer
        currentImage = nil
        pending = try await nextImage()
    }

    /// The next sample's image; samples without one are skipped.
    private func nextImage() async throws -> (buffer: CVReadOnlyPixelBuffer, seconds: Double)? {
        do {
            while let sample = try await provider.next() {
                if case let .pixelBuffer(buffer) = sample.content { return (buffer, sample.presentationTimeStamp.seconds) }
            }
            return nil
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AppPreviewError.readerFailed(error.localizedDescription)
        }
    }
}
