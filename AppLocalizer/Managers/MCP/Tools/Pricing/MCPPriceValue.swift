//
//  MCPPriceValue.swift
//  AppLocalizer
//

import Foundation

/// Prices as the price tools exchange them: JSON numbers in the
/// territory's currency (219.9, 2499), read back from numbers or numeric
/// strings.
enum MCPPriceValue {
    /// A whole amount as an integer, anything else as a number with its
    /// decimals: `219.90` → `219.9`, `2499` → `2499`.
    static func json(_ amount: Decimal) -> JSONValue {
        if amount == amount.rounded(scale: 0), let whole = Int(exactly: NSDecimalNumber(decimal: amount)) {
            return .int(whole)
        }
        // Through its text, so 39.99 stays 39.99 instead of picking up
        // binary noise on the way to a Double.
        return .double(Double(amount.description) ?? NSDecimalNumber(decimal: amount).doubleValue)
    }

    /// A price from a number or a numeric string ("109.90", or "109,90"
    /// with a comma as the only separator); nil for anything else or a
    /// price that isn't positive.
    static func decimal(from value: JSONValue) -> Decimal? {
        let amount: Decimal? = switch value {
        case let .int(whole): Decimal(whole)
        // Through its shortest text, so 109.9 stays 109.9 instead of
        // picking up binary noise.
        case let .double(number) where number.isFinite: Decimal(string: String(number), locale: Locale(identifier: "en_US_POSIX"))
        case let .string(text): parse(text)
        default: nil
        }
        guard let amount, amount > 0 else { return nil }
        return amount
    }

    private static func parse(_ text: String) -> Decimal? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.contains("."), trimmed.count(where: { $0 == "," }) == 1 {
            trimmed = trimmed.replacingOccurrences(of: ",", with: ".")
        }
        guard !trimmed.isEmpty, trimmed.allSatisfy({ $0.isNumber || $0 == "." }) else { return nil }
        return Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX"))
    }
}
