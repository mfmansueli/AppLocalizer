//
//  IconPalette.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import ImageIO

/// Colors picked from an app icon, to color AppLocalizer's starters when
/// there's no design project: the icon's light and dark ends and a
/// darkest shade for bands.
struct IconPalette: Hashable, Sendable {
    /// "#7C86FF".
    var light: String
    /// "#3A2FB8".
    var dark: String

    /// A sRGB color with components from 0 to 1.
    private struct RGB {
        var red: Double
        var green: Double
        var blue: Double

        init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        init?(hex: String) {
            var text = hex.trimmingCharacters(in: .whitespaces)
            if text.hasPrefix("#") { text.removeFirst() }
            guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        }

        var hex: String {
            let parts = [red, green, blue].map { Int((min(max($0, 0), 1) * 255).rounded()) }
            return String(format: "#%02X%02X%02X", parts[0], parts[1], parts[2])
        }

        func mixed(with other: RGB, _ amount: Double) -> RGB {
            RGB(red: red + (other.red - red) * amount, green: green + (other.green - green) * amount, blue: blue + (other.blue - blue) * amount)
        }

        static let white = RGB(red: 1, green: 1, blue: 1)
        static let black = RGB(red: 0, green: 0, blue: 0)
    }

    /// The darkest shade, for a band behind white text.
    var darkest: String { shade(dark, toward: .black, 0.45) }

    /// The caption-above starter's gradient.
    var gradient: [String] { [shade(light, toward: .black, 0.08), shade(dark, toward: .black, 0.25)] }

    /// The panorama starter's pale stops, alternating the two ends.
    var panorama: [String] {
        [
            shade(light, toward: .white, 0.78), shade(dark, toward: .white, 0.82), shade(light, toward: .white, 0.86),
            shade(dark, toward: .white, 0.74), shade(light, toward: .white, 0.8),
        ]
    }

    private func shade(_ hex: String, toward target: RGB, _ amount: Double) -> String {
        (RGB(hex: hex) ?? .black).mixed(with: target, amount).hex
    }

    // MARK: - Reading an icon

    /// The palette of `icon`, or nil without one (or when it can't be read).
    static func palette(for icon: AppIcon?) async -> IconPalette? {
        switch icon {
        case let .symbol(_, top, bottom):
            return IconPalette(light: hex(top), dark: hex(bottom))
        case let .remote(url):
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
            return palette(of: image)
        case nil:
            return nil
        }
    }

    /// The average colors of the image's top and bottom thirds.
    static func palette(of image: CGImage) -> IconPalette? {
        let size = 24
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
            return true
        }
        guard drawn else { return nil }
        // Row 0 is the top in the buffer's memory order.
        func average(rows: Range<Int>) -> RGB? {
            var total = (0.0, 0.0, 0.0)
            var count = 0.0
            for row in rows {
                for column in 0..<size {
                    let index = (row * size + column) * 4
                    let alpha = Double(pixels[index + 3]) / 255
                    guard alpha > 0.5 else { continue }
                    total.0 += Double(pixels[index]) / 255 / alpha
                    total.1 += Double(pixels[index + 1]) / 255 / alpha
                    total.2 += Double(pixels[index + 2]) / 255 / alpha
                    count += 1
                }
            }
            guard count > 0 else { return nil }
            return RGB(red: total.0 / count, green: total.1 / count, blue: total.2 / count)
        }
        guard let top = average(rows: 0..<size / 3), let bottom = average(rows: size * 2 / 3..<size) else { return nil }
        return IconPalette(light: top.hex, dark: bottom.hex)
    }

    private static func hex(_ value: UInt32) -> String {
        String(format: "#%06X", value & 0xFFFFFF)
    }
}
