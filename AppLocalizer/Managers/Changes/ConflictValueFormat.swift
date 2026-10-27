//
//  ConflictValueFormat.swift
//  AppLocalizer
//

import Foundation

/// How a `ConflictCheck` turns the raw value it read into what the review
/// row shows: text as it is, or a decimal price in a currency.
enum ConflictValueFormat: Hashable, Codable, Sendable {
    case text
    /// `customerPrice` strings like "199.9", shown as e.g. "R$ 199,90".
    case currency(code: String, localeIdentifier: String)

    func display(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return String(localized: "Empty") }
        switch self {
        case .text:
            return raw
        case let .currency(code, localeIdentifier):
            guard let amount = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else { return raw }
            return amount.formatted(.currency(code: code).locale(Locale(identifier: localeIdentifier)))
        }
    }
}
