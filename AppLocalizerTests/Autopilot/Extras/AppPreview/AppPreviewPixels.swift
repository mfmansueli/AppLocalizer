//
//  AppPreviewPixels.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
@testable import AppLocalizer

/// Reads single pixels out of App Preview images for the tests.
enum AppPreviewPixels {
    /// The sRGB color of the pixel at `point`, measured from the image's
    /// top-left corner.
    static func color(of image: CGImage, at point: CGPoint) -> TemplateColor? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var pixel = [UInt8](repeating: 0, count: 4)
        let drawn = pixel.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            let row = CGFloat(image.height) - point.y.rounded(.down) - 1
            context.draw(image, in: CGRect(x: -point.x.rounded(.down), y: -row, width: CGFloat(image.width), height: CGFloat(image.height)))
            return true
        }
        guard drawn else { return nil }
        return TemplateColor(red: Double(pixel[0]) / 255, green: Double(pixel[1]) / 255, blue: Double(pixel[2]) / 255, alpha: Double(pixel[3]) / 255)
    }

    /// Whether two colors match within `tolerance` per component.
    static func matches(_ color: TemplateColor?, _ expected: TemplateColor, tolerance: Double = 0.08) -> Bool {
        guard let color else { return false }
        return abs(color.red - expected.red) <= tolerance && abs(color.green - expected.green) <= tolerance
            && abs(color.blue - expected.blue) <= tolerance
    }
}
