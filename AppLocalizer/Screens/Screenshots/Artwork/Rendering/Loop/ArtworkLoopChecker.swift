//
//  ArtworkLoopChecker.swift
//  AppLocalizer
//

import AVFoundation
import CoreGraphics
import Foundation

/// Checks a motion loop the way Apple will play it: 20 seconds at 30 fps
/// at the artwork's size, no sound track, and the last frame the same as
/// the first, so it repeats without a jump.
enum ArtworkLoopChecker {
    /// How far apart the first and last frames may be, on average per
    /// color channel (0–255), after the encoder's rounding.
    static let seamTolerance = 3.0

    /// What's wrong with the file (empty when it loops cleanly), and
    /// whether its last frame matches its first.
    static func check(_ url: URL, size: PixelSize) async -> (problems: [String], isSeamless: Bool) {
        let asset = AVURLAsset(url: url)
        var problems: [String] = []
        guard let video = try? await asset.loadTracks(withMediaType: .video).first else {
            return ([String(localized: "The loop has no video.")], false)
        }
        let seconds = await (try? asset.load(.duration).seconds) ?? 0
        if abs(seconds - Double(AutopilotArtworkMotion.loopSeconds)) > 0.05 {
            problems.append(String(localized: "The loop runs \(AutopilotRun.timeTitle(seconds)), not 0:20."))
        }
        let rate = await (try? video.load(.nominalFrameRate)) ?? 0
        if abs(Double(rate) - Double(AutopilotArtworkMotion.loopFramesPerSecond)) > 0.5 {
            problems.append(String(localized: "The loop plays at \(Int(rate.rounded())) fps, not 30."))
        }
        if let natural = try? await video.load(.naturalSize), Int(natural.width) != size.width || Int(natural.height) != size.height {
            problems.append(String(localized: "The loop is \(Int(natural.width)) × \(Int(natural.height)), not \(size.title)."))
        }
        if let audio = try? await asset.loadTracks(withMediaType: .audio), !audio.isEmpty {
            problems.append(String(localized: "The loop has sound; search results can’t unmute, so it must be silent."))
        }
        let difference = await seamDifference(asset, seconds: seconds, framesPerSecond: Double(rate))
        let isSeamless = difference.map { $0 <= seamTolerance } ?? false
        if !isSeamless {
            problems.append(String(localized: "The last frame doesn’t match the first, so the loop jumps when it repeats."))
        }
        return (problems, isSeamless)
    }

    /// The first and last frames' average difference per channel.
    static func seamDifference(_ asset: AVAsset, seconds: Double, framesPerSecond: Double) async -> Double? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: 320, height: 320)
        let last = max(0, seconds - 1 / max(framesPerSecond, 1))
        guard let first = try? await generator.image(at: .zero).image,
              let end = try? await generator.image(at: CMTime(seconds: last, preferredTimescale: 600)).image
        else { return nil }
        return difference(first, end)
    }

    /// The average difference per channel of two images, drawn at the same
    /// small size.
    static func difference(_ lhs: CGImage, _ rhs: CGImage) -> Double? {
        let width = 96
        let height = max(1, Int((Double(width) * Double(lhs.height) / Double(max(lhs.width, 1))).rounded()))
        guard let left = pixels(lhs, width: width, height: height), let right = pixels(rhs, width: width, height: height) else { return nil }
        var total = 0
        for index in left.indices where index % 4 != 3 {
            total += abs(Int(left[index]) - Int(right[index]))
        }
        return Double(total) / Double(width * height * 3)
    }

    private static func pixels(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? bytes : nil
    }
}
