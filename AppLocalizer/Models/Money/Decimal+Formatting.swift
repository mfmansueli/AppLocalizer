//
//  Decimal+Formatting.swift
//  AppLocalizer
//

import Foundation

extension Decimal {
    /// Rounded to `scale` decimal places; half away from zero by default,
    /// like the App Store's own rounding.
    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Exactly `places` decimals with a `.`: `0.5.fixed(2)` → `"0.50"`.
    func fixed(_ places: Int) -> String {
        let text = NSDecimalNumber(decimal: rounded(scale: places)).stringValue
        guard places > 0 else { return text }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        let fraction = parts.count > 1 ? String(parts[1]) : ""
        return parts[0] + "." + fraction.padding(toLength: places, withPad: "0", startingAt: 0)
    }

    /// At most `places` decimals, trailing zeros dropped: `0.800` → `"0.8"`,
    /// `1.000` → `"1"`.
    func trimmed(maxPlaces places: Int) -> String {
        NSDecimalNumber(decimal: rounded(scale: places)).stringValue
    }

    /// A fraction as a percent number without the sign: `0.3` → `"30"`,
    /// `0.325` → `"32.5"`.
    var percentText: String {
        (self * 100).trimmed(maxPlaces: 1)
    }

    /// A Double read through its shortest description, so `0.85` becomes
    /// exactly 0.85 rather than 0.85000000000000002.
    init(exactly double: Double) {
        self = Decimal(string: "\(double)", locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(double)
    }
}
