//
//  AppIconMargin.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The transparent margin around an icon's artwork. A Mac build's icon sits
/// inside one (the Mac's icon grid leaves about a tenth of each side, and
/// the shadow goes there), so beside iPhone icons, which fill their image,
/// it looks smaller. Cropping to the opaque pixels makes every icon fill
/// its tile.
enum AppIconMargin {
    /// Pixels at least this opaque are the icon; a Mac icon's shadow is
    /// fainter.
    static let opaqueAlpha: UInt8 = 128

    /// Decodes an icon at most `maxPixelSize` wide, without its margin.
    static func decodeTrimmed(_ data: Data, maxPixelSize: Int = 192) -> CGImage? {
        ScreenshotThumbnailer.thumbnail(data, maxPixelSize: maxPixelSize).map(trimmed)
    }

    /// `image` cropped to the square around its opaque pixels; `image`
    /// itself when they reach its edges or it has none.
    static func trimmed(_ image: CGImage) -> CGImage {
        guard let bounds = opaqueBounds(of: image) else { return image }
        let side = max(bounds.width, bounds.height)
        guard side < CGFloat(min(image.width, image.height)) else { return image }
        let x = min(max(0, (bounds.midX - side / 2).rounded()), CGFloat(image.width) - side)
        let y = min(max(0, (bounds.midY - side / 2).rounded()), CGFloat(image.height) - side)
        return image.cropping(to: CGRect(x: x, y: y, width: side, height: side)) ?? image
    }

    /// The smallest rectangle holding every opaque pixel, with the origin
    /// at the top left as `CGImage.cropping(to:)` takes it; nil when no
    /// pixel is opaque.
    static func opaqueBounds(of image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        // Row 0 is the top in the buffer's memory order.
        var minX = width, minY = height, maxX = -1, maxY = -1
        for row in 0..<height {
            for column in 0..<width where pixels[(row * width + column) * 4 + 3] >= opaqueAlpha {
                minX = min(minX, column)
                maxX = max(maxX, column)
                minY = min(minY, row)
                maxY = max(maxY, row)
            }
        }
        guard maxX >= 0 else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }
}
