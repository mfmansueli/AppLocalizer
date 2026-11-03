//
//  AppPreviewInspector.swift
//  AppLocalizer
//

import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation

/// Reads an App Preview file back: its length, displayed size, frame rate,
/// video codec, sound channels and file size, so what's checked is the
/// file itself rather than what AppLocalizer meant to write.
enum AppPreviewInspector {
    /// Nil when the file isn't a movie with video.
    static func facts(of url: URL) async -> AppPreviewFacts? {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration),
              let video = try? await asset.loadTracks(withMediaType: .video).first,
              let naturalSize = try? await video.load(.naturalSize),
              let transform = try? await video.load(.preferredTransform),
              let frameRate = try? await video.load(.nominalFrameRate),
              let formats = try? await video.load(.formatDescriptions)
        else { return nil }
        let shown = CGRect(origin: .zero, size: naturalSize).applying(transform)
        let pixelSize = PixelSize(width: Int(abs(shown.width).rounded()), height: Int(abs(shown.height).rounded()))
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return await AppPreviewFacts(
            seconds: duration.seconds,
            pixelSize: pixelSize,
            framesPerSecond: Double(frameRate),
            codec: codec(of: formats.first),
            audioChannels: audioChannels(of: asset),
            byteCount: (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        )
    }

    static func codec(of format: CMFormatDescription?) -> AppPreviewFacts.Codec {
        guard let format else { return .other }
        switch CMFormatDescriptionGetMediaSubType(format) {
        case kCMVideoCodecType_H264: return .h264
        case kCMVideoCodecType_AppleProRes422HQ: return .proRes422HQ
        default: return .other
        }
    }

    /// The first sound track's channels, or 0 without one.
    private static func audioChannels(of asset: AVURLAsset) async -> Int {
        guard let audio = try? await asset.loadTracks(withMediaType: .audio).first,
              let format = try? await audio.load(.formatDescriptions).first,
              let description = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        else { return 0 }
        return Int(description.pointee.mChannelsPerFrame)
    }
}
