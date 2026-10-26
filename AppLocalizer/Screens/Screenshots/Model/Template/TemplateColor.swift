//
//  TemplateColor.swift
//  AppLocalizer
//

import Foundation

/// A color as a template writes it: `#7A80FF`, `#7AF`, `#7A80FFCC` or
/// `rgba(255,255,255,0.84)`. Components are sRGB, 0–1.
struct TemplateColor: Hashable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1

    static let black = TemplateColor(red: 0, green: 0, blue: 0)
    static let white = TemplateColor(red: 1, green: 1, blue: 1)

    /// Parses the template's text, or nil when it isn't a color.
    init?(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.hasPrefix("#") {
            self.init(hex: String(trimmed.dropFirst()))
        } else if trimmed.hasPrefix("rgb") {
            self.init(function: trimmed)
        } else {
            return nil
        }
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// The text for a parsed or picked color: `#RRGGBB`, with alpha as a
    /// fourth byte when it isn't opaque.
    var hexString: String {
        let bytes = [red, green, blue].map { Int(($0 * 255).rounded()) }
        let hex = bytes.map { String(format: "%02X", $0) }.joined()
        return alpha < 1 ? "#\(hex)\(String(format: "%02X", Int((alpha * 255).rounded())))" : "#\(hex)"
    }

    private init?(hex: String) {
        guard hex.allSatisfy(\.isHexDigit) else { return nil }
        let digits: [Character] = switch hex.count {
        case 3, 4: hex.flatMap { [$0, $0] }
        case 6, 8: Array(hex)
        default: []
        }
        guard !digits.isEmpty else { return nil }
        let values = stride(from: 0, to: digits.count, by: 2).compactMap { Int(String(digits[$0...$0 + 1]), radix: 16) }
        red = Double(values[0]) / 255
        green = Double(values[1]) / 255
        blue = Double(values[2]) / 255
        alpha = values.count == 4 ? Double(values[3]) / 255 : 1
    }

    private init?(function: String) {
        guard let open = function.firstIndex(of: "("), let close = function.lastIndex(of: ")"), open < close else { return nil }
        let numbers = function[function.index(after: open)..<close]
            .split(separator: ",")
            .map { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.count == 3 || numbers.count == 4, numbers.allSatisfy({ $0 != nil }) else { return nil }
        let values = numbers.compactMap(\.self)
        guard values.prefix(3).allSatisfy({ (0...255).contains($0) }) else { return nil }
        red = values[0] / 255
        green = values[1] / 255
        blue = values[2] / 255
        alpha = values.count == 4 ? min(max(values[3], 0), 1) : 1
    }
}
