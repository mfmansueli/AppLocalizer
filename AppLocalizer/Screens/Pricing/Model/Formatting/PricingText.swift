//
//  PricingText.swift
//  AppLocalizer
//

import Foundation

/// Small, locale-independent formatters for the engine's generated text
/// (reason lines, breakdown steps, results). They match the design copy
/// exactly, in English, so tests can compare strings.
enum PricingText {
    /// `4800` → `"4,800"`.
    static func grouped(_ number: Int) -> String {
        integerFormat.format(Decimal(number))
    }

    /// A fraction as a percent with fixed decimals: `0.00646` → `"0.65%"`.
    static func percent(_ fraction: Double, places: Int = 2) -> String {
        Decimal(exactly: fraction * 100).fixed(places) + "%"
    }

    /// A "feels like" ratio to one decimal, halves rounded up: `1.9996` →
    /// `"2.0×"`.
    static func ratio(_ value: Decimal) -> String {
        ((value * 10).rounded(scale: 0) / 10).fixed(1) + "×"
    }

    /// `"Jul 14, 2026"`, in GMT so a date doesn't shift with the Mac's zone.
    static func date(_ date: Date) -> String {
        date.formatted(dateStyle)
    }

    /// A signed whole percent from a ratio's change, rounded like
    /// JavaScript's `Math.round` (halves up): `0.5 - 1` → `"−50%"`,
    /// `+18%`, `0%`. The minus is U+2212.
    static func signedPercent(_ percent: Int) -> String {
        let sign = percent > 0 ? "+" : percent < 0 ? "−" : ""
        return sign + "\(abs(percent))%"
    }

    private static let integerFormat = CurrencyFormat(
        code: "", prefix: "", suffix: "", decimals: 0, groupingSeparator: ",", decimalSeparator: "."
    )

    private static let dateStyle = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US"), timeZone: .gmt)
}
