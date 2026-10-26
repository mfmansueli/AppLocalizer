//
//  CurrencyFormat+Parsing.swift
//  AppLocalizer
//

import Foundation

extension CurrencyFormat {
    /// Reads back an amount this format wrote, such as “R$ 1.299,90” → 1299.90.
    /// Returns nil for text it didn't write.
    func parse(_ text: String) -> Decimal? {
        var body = text.trimmingCharacters(in: .whitespaces)
        let isNegative = body.hasPrefix("−") || body.hasPrefix("-")
        if isNegative { body.removeFirst() }
        if !prefix.isEmpty {
            guard body.hasPrefix(prefix) else { return nil }
            body.removeFirst(prefix.count)
        }
        if !suffix.isEmpty {
            guard body.hasSuffix(suffix) else { return nil }
            body.removeLast(suffix.count)
        }
        if !groupingSeparator.isEmpty { body = body.replacingOccurrences(of: groupingSeparator, with: "") }
        if decimals > 0 { body = body.replacingOccurrences(of: decimalSeparator, with: ".") }
        guard !body.isEmpty, body.allSatisfy({ $0.isNumber || $0 == "." }),
              let amount = Decimal(string: body, locale: Locale(identifier: "en_US_POSIX"))
        else { return nil }
        return isNegative ? -amount : amount
    }
}
