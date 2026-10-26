//
//  CurrencyFormat.swift
//  AppLocalizer
//

import Foundation

/// How the App Store writes prices in one currency: symbol placement,
/// decimals and separators, e.g. `R$ 219,90`, `39,99 €`, `₩56,000`.
///
/// Every space is a plain U+0020 (never a non-breaking space), so strings
/// compare cleanly in tests; views keep prices on one line with
/// `.lineLimit(1)`. Swiss francs group with ’ (U+2019), as Apple does.
struct CurrencyFormat: Hashable, Sendable {
    /// ISO 4217 code, e.g. `BRL`.
    var code: String
    /// Text before the number, including its space: `"R$ "`, `"£"`.
    var prefix: String
    /// Text after the number, including its space: `" €"`, `" kr"`.
    var suffix: String
    /// 2 for most currencies; 0 for JPY, KRW, IDR, VND, CLP, COP and others.
    var decimals: Int
    var groupingSeparator: String
    var decimalSeparator: String

    /// Rounds half away from zero to `decimals` places and formats, e.g.
    /// `219.9` → `R$ 219,90`. Negative amounts get a leading − (U+2212).
    func format(_ amount: Decimal) -> String {
        format(amount, decimals: decimals)
    }

    /// The same, rounded to whole units: `79.96` → `$80`.
    func formatWhole(_ amount: Decimal) -> String {
        format(amount, decimals: 0)
    }

    private func format(_ amount: Decimal, decimals: Int) -> String {
        let rounded = amount.magnitude.rounded(scale: decimals)
        let digits = rounded.fixed(decimals).split(separator: ".", omittingEmptySubsequences: false)
        let integer = grouped(String(digits[0]))
        let fraction = decimals > 0 && digits.count > 1 ? decimalSeparator + digits[1] : ""
        let sign = amount < 0 && rounded != 0 ? "−" : ""
        return sign + prefix + integer + fraction + suffix
    }

    private func grouped(_ integer: String) -> String {
        var groups: [Substring] = []
        var end = integer.endIndex
        while end > integer.startIndex {
            let start = integer.index(end, offsetBy: -3, limitedBy: integer.startIndex) ?? integer.startIndex
            groups.insert(integer[start..<end], at: 0)
            end = start
        }
        return groups.joined(separator: groupingSeparator)
    }
}
