//
//  CaptureBlankness.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// How much of a capture is one flat area: the largest rectangle of
/// flat cells below the status bar, as a share of that part of the
/// screen. A blank or black screen, an almost empty sheet or a screen
/// still loading shows as mostly flat. Real screens stayed at or under
/// 0.40, even a short list with space below it (MB Admin's and Alba's
/// captures). The blank iPhone Duo frames and MB Admin's nearly empty
/// "comparar produtos" sheet measured 0.77–1.00.
enum CaptureBlankness {
    /// At or above this, the capture is mostly blank.
    static let mostlyBlank = 0.6
    /// The grid's columns; rows follow the image's shape.
    static let columns = 24
    /// A cell is flat when its gray values differ by this much at most.
    static let flatRange = 6

    /// The largest flat rectangle's share of the screen below the status
    /// bar, 0–1; nil for an image too small to judge.
    static func largestBlankShare(of image: CGImage) -> Double? {
        let width = columns * 10
        let height = Int((Double(image.height) / Double(image.width) * Double(width)).rounded())
        guard image.width > 0, height >= width / 4 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        return largestBlankShare(gray: pixels, width: width, height: height)
    }

    /// The same measure on gray pixels, top row first.
    static func largestBlankShare(gray pixels: [UInt8], width: Int, height: Int) -> Double? {
        let cell = width / columns
        guard cell > 0 else { return nil }
        let rows = height / cell
        let top = Int((Double(rows) * CaptureTextAnalyzer.statusBarHeight).rounded(.up))
        guard rows > top else { return nil }
        var heights = [Int](repeating: 0, count: columns)
        var largest = 0
        for row in top..<rows {
            for column in 0..<columns {
                heights[column] = isFlat(pixels, width: width, cell: cell, row: row, column: column) ? heights[column] + 1 : 0
            }
            largest = max(largest, largestRectangle(under: heights))
        }
        return Double(largest) / Double((rows - top) * columns)
    }

    private static func isFlat(_ pixels: [UInt8], width: Int, cell: Int, row: Int, column: Int) -> Bool {
        var low = UInt8.max
        var high = UInt8.min
        for y in row * cell..<(row + 1) * cell {
            let start = y * width + column * cell
            for value in pixels[start..<start + cell] {
                low = min(low, value)
                high = max(high, value)
            }
        }
        return Int(high) - Int(low) <= flatRange
    }

    /// The largest rectangle under a histogram of flat-cell heights.
    private static func largestRectangle(under heights: [Int]) -> Int {
        var largest = 0
        for start in heights.indices {
            var lowest = Int.max
            for end in start..<heights.count {
                lowest = min(lowest, heights[end])
                if lowest == 0 { break }
                largest = max(largest, lowest * (end - start + 1))
            }
        }
        return largest
    }
}
