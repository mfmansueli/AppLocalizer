//
//  ArtworkPixels.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A render's pixels, scaled down to at most `maximumWidth` across, as
/// 8-bit RGBA with its alpha kept: enough to see its edges and whether
/// any of it is see-through.
struct ArtworkPixels {
    static let maximumWidth = 480

    let width: Int
    let height: Int
    private let bytes: [UInt8]

    init?(_ image: CGImage) {
        let scale = min(1, Double(Self.maximumWidth) / Double(max(1, image.width)))
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    /// The pixel at `x`, `y` from the top left, un-premultiplied.
    func color(x: Int, y: Int) -> TemplateColor {
        let index = (min(max(y, 0), height - 1) * width + min(max(x, 0), width - 1)) * 4
        let alpha = Double(bytes[index + 3]) / 255
        guard alpha > 0 else { return TemplateColor(red: 0, green: 0, blue: 0, alpha: 0) }
        return TemplateColor(
            red: min(1, Double(bytes[index]) / 255 / alpha), green: min(1, Double(bytes[index + 1]) / 255 / alpha),
            blue: min(1, Double(bytes[index + 2]) / 255 / alpha), alpha: alpha
        )
    }

    /// Some pixel isn't fully opaque.
    var hasTransparentPixels: Bool {
        stride(from: 3, to: bytes.count, by: 4).contains { bytes[$0] < 255 }
    }

    /// The outermost ring of pixels, all four sides.
    var edgeColors: [TemplateColor] {
        var colors: [TemplateColor] = []
        for x in 0..<width {
            colors.append(color(x: x, y: 0))
            colors.append(color(x: x, y: height - 1))
        }
        for y in 1..<max(1, height - 1) {
            colors.append(color(x: 0, y: y))
            colors.append(color(x: width - 1, y: y))
        }
        return colors
    }

    /// Whether `image` has an alpha channel at all.
    static func hasAlphaChannel(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: false
        default: true
        }
    }
}
