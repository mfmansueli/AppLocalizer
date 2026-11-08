//
//  AppPreviewMotionReader.swift
//  AppLocalizer
//

import AVFoundation
import CoreGraphics
import Foundation

/// Reads how much a stretch of a recording moves: small gray frames, a
/// step apart, without the status bar (its clock) and the Home indicator.
enum AppPreviewMotionReader {
    /// The width frames are compared at.
    static let width: CGFloat = 96
    /// A pixel changed when its gray level moved this much of 255.
    static let pixelChange = 10
    /// The share of the frame left out at the top and the bottom.
    static let topInset = 0.08
    static let bottomInset = 0.04

    /// Nil when too few frames can be read.
    static func motion(of url: URL, from start: Double, to end: Double) async -> AutopilotMomentMotion? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.maximumSize = CGSize(width: width, height: 0)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        var changes: [Double] = []
        var previous: [UInt8]?
        var time = start
        while time <= end {
            let instant = CMTime(seconds: time, preferredTimescale: 600)
            time += AutopilotMomentMotion.step
            guard let image = try? await generator.image(at: instant).image else { continue }
            let frame = gray(image)
            if let previous { changes.append(changedShare(previous, frame, width: image.width, height: image.height)) }
            previous = frame
        }
        return changes.count >= 2 ? AutopilotMomentMotion(changes: changes) : nil
    }

    private static func gray(_ image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
            )
            context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return pixels
    }

    /// 0–1: the share of the compared rows' pixels that changed.
    static func changedShare(_ before: [UInt8], _ after: [UInt8], width: Int, height: Int) -> Double {
        guard before.count == after.count, before.count == width * height, width > 0 else { return 0 }
        let top = Int(Double(height) * topInset)
        let bottom = Int(Double(height) * (1 - bottomInset))
        guard bottom > top else { return 0 }
        var changed = 0
        for row in top..<bottom {
            for index in (row * width)..<((row + 1) * width) where abs(Int(before[index]) - Int(after[index])) > pixelChange {
                changed += 1
            }
        }
        return Double(changed) / Double((bottom - top) * width)
    }
}
