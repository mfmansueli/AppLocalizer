//
//  ArtworkLoopBitmap.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A loop's still layer made ready to draw 600 times: in the movie's own
/// pixel format (32-bit BGRA, premultiplied, sRGB), so each frame copies or
/// blends it without converting, and, for a layer on clear, cut to the
/// part that has anything in it, so each frame touches only that part.
nonisolated enum ArtworkLoopBitmap {
    /// The encoder's pixel buffers' layout.
    static let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

    /// Clear pixels kept around the content, so its edges blend with
    /// clear as they do over the whole frame when the phones float a
    /// fraction of a pixel.
    static let margin = 4

    /// `image` redrawn in the movie's format, and, unless `opaque`, the
    /// rectangle (top-left origin, in pixels) that has anything in it;
    /// nil when the layer is empty.
    static func prepare(_ image: CGImage, opaque: Bool) -> (image: CGImage, bounds: CGRect)? {
        let width = image.width
        let height = image.height
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: bitmapInfo
              )
        else { return nil }
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let full = CGRect(x: 0, y: 0, width: width, height: height)
        guard !opaque else { return context.makeImage().map { ($0, full) } }
        guard let data = context.data,
              let bounds = Self.bounds(of: data, width: width, height: height, bytesPerRow: context.bytesPerRow),
              let cut = context.makeImage()?.cropping(to: bounds)
        else { return nil }
        return (cut, bounds)
    }

    /// The rectangle (top-left origin) around every pixel that isn't
    /// clear, grown by `margin`; nil when all are. Premultiplied, a clear
    /// pixel is all zeros: empty rows are found with `memcmp`, and only the
    /// rows with something are read pixel by pixel, from each end inwards.
    static func bounds(of data: UnsafeMutableRawPointer, width: Int, height: Int, bytesPerRow: Int) -> CGRect? {
        let rowBytes = width * 4
        let zeros = [UInt8](repeating: 0, count: rowBytes)
        var minX = width
        var maxX = -1
        var minY = height
        var maxY = -1
        for y in 0..<height {
            let row = data + y * bytesPerRow
            guard zeros.withUnsafeBytes({ memcmp(row, $0.baseAddress, rowBytes) }) != 0 else { continue }
            minY = min(minY, y)
            maxY = y
            let pixels = row.assumingMemoryBound(to: UInt32.self)
            var left = 0
            while left < minX, pixels[left] == 0 { left += 1 }
            minX = min(minX, left)
            var right = width - 1
            while right > maxX, pixels[right] == 0 { right -= 1 }
            maxX = max(maxX, right)
        }
        guard maxY >= 0 else { return nil }
        let left = max(0, minX - margin)
        let top = max(0, minY - margin)
        let right = min(width, maxX + 1 + margin)
        let bottom = min(height, maxY + 1 + margin)
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    /// `bounds` (top-left origin) in a context of `height` with Core
    /// Graphics' bottom-left origin.
    static func flipped(_ bounds: CGRect, height: CGFloat) -> CGRect {
        CGRect(x: bounds.minX, y: height - bounds.maxY, width: bounds.width, height: bounds.height)
    }
}
