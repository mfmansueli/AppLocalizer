//
//  AppPreviewAssembler.swift
//  AppLocalizer
//

import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation

/// Puts the App Preview together: each segment's stretch of the Simulator
/// recording, played at the spec's constant frame rate inside its styled
/// frame (aspect-filling the rounded screen at `appRect`), then the end
/// card faded in over the last frame, with the music under it. The file is
/// written by `AppPreviewWriter`; a cancelled or failed run deletes it. The
/// recording's own orientation is used as it is: Simulator recordings carry
/// no rotation.
struct AppPreviewAssembler {
    var spec: AppPreviewSpec
    /// Where the recording plays, in pixels from the top-left corner.
    var appRect: CGRect
    var appCornerRadius: CGFloat
    var bitRate = 10_000_000
    /// How long the end card takes to fade in.
    var crossFadeSeconds = 0.4

    /// `frames` holds one frame image per segment, in the same order.
    func assemble(
        recording: URL, segments: [AppPreviewSegment], frames: [CGImage], endCard: CGImage, endCardSeconds: Double, output: URL,
        soundtrack: AppPreviewSoundtrack? = nil
    ) async throws -> AppPreviewOutput {
        guard frames.count == segments.count else { throw AppPreviewError.drawingFailed }
        let asset = AVURLAsset(url: recording)
        let main = try await Source(asset: asset, track: Self.videoTrack(of: asset))
        // A moment recorded again plays from its own take.
        var takes: [URL: Source] = [:]
        for url in Set(segments.compactMap(\.source)) {
            let take = AVURLAsset(url: url)
            takes[url] = try await Source(asset: take, track: Self.videoTrack(of: take))
        }
        let writer = try AppPreviewWriter(output: output, spec: spec, bitRate: bitRate, soundtrack: soundtrack)
        do {
            var last: CGImage?
            for (index, segment) in segments.enumerated() {
                let keepLast = index == segments.count - 1
                let source = segment.source.flatMap { takes[$0] } ?? main
                if let kept = try await write(segment, frame: frames[index], from: source, to: writer, keepLast: keepLast) { last = kept }
            }
            try await writeEndCard(endCard, over: last, seconds: endCardSeconds, to: writer)
            try await writer.finish()
        } catch {
            writer.cancel()
            try? FileManager.default.removeItem(at: output)
            throw error
        }
        let attributes = try? FileManager.default.attributesOfItem(atPath: output.path)
        let bytes = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        return AppPreviewOutput(url: output, seconds: writer.nextFrameSeconds, pixelSize: spec.pixelSize, byteCount: bytes)
    }

    // MARK: - Segments

    /// The recording and its video track.
    private struct Source {
        var asset: AVURLAsset
        var track: AVAssetTrack
    }

    private static func videoTrack(of asset: AVURLAsset) async throws -> AVAssetTrack {
        let tracks: [AVAssetTrack]
        do {
            tracks = try await asset.loadTracks(withMediaType: .video)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AppPreviewError.unreadableRecording
        }
        guard let track = tracks.first else { throw AppPreviewError.noVideoTrack }
        return track
    }

    /// Writes one segment's frames and, with `keepLast`, returns its last
    /// frame as drawn.
    private func write(
        _ segment: AppPreviewSegment, frame: CGImage, from source: Source, to writer: AppPreviewWriter, keepLast: Bool
    ) async throws -> CGImage? {
        let fps = Double(max(spec.framesPerSecond, 1))
        let count = max(1, Int((segment.duration * fps).rounded()))
        let reader = try AppPreviewSegmentReader(asset: source.asset, track: source.track, segment: segment)
        defer { reader.cancel() }
        var fallback: CGImage?
        var kept: CGImage?
        for index in 0..<count {
            var image = try await reader.image(at: segment.start + Double(index) / fps)
            if image == nil {
                if fallback == nil { fallback = await Self.still(of: source.asset, at: segment.start) }
                image = fallback
            }
            let keep = keepLast && index == count - 1
            let drawn = try await writer.appendFrame(keepingImage: keep) { context in
                draw(frame: frame, recording: image, in: context)
            }
            if keep { kept = drawn }
        }
        return kept
    }

    /// The frame, then the recording aspect-filling the rounded screen.
    private func draw(frame: CGImage, recording: CGImage?, in context: CGContext) {
        context.draw(frame, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
        guard let recording else { return }
        let target = CGRect(x: appRect.minX, y: CGFloat(context.height) - appRect.maxY, width: appRect.width, height: appRect.height)
        let radius = min(appCornerRadius, target.width / 2, target.height / 2)
        let scale = max(target.width / CGFloat(max(recording.width, 1)), target.height / CGFloat(max(recording.height, 1)))
        let filled = CGSize(width: CGFloat(recording.width) * scale, height: CGFloat(recording.height) * scale)
        context.saveGState()
        context.addPath(CGPath(roundedRect: target, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.clip()
        context.draw(recording, in: CGRect(x: target.midX - filled.width / 2, y: target.midY - filled.height / 2, width: filled.width, height: filled.height))
        context.restoreGState()
    }

    /// The recording's image at `seconds`, for a stretch the reader found
    /// no image in.
    private static func still(of asset: AVURLAsset, at seconds: Double) async -> CGImage? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .positiveInfinity
        generator.requestedTimeToleranceAfter = .zero
        return try? await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600)).image
    }

    // MARK: - End card

    private func writeEndCard(_ card: CGImage, over last: CGImage?, seconds: Double, to writer: AppPreviewWriter) async throws {
        let fps = Double(max(spec.framesPerSecond, 1))
        let count = max(1, Int((seconds * fps).rounded()))
        let fade = last == nil ? 0 : min(count, Int((crossFadeSeconds * fps).rounded()))
        for index in 0..<count {
            let alpha = index < fade ? CGFloat(index + 1) / CGFloat(fade) : 1
            try await writer.appendFrame { context in
                let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
                if alpha < 1, let last { context.draw(last, in: rect) }
                context.setAlpha(alpha)
                context.draw(card, in: rect)
            }
        }
    }
}
