//
//  PriceRounding.swift
//  AppLocalizer
//

import Foundation

/// The strategy's rounding choice. `.auto` uses each currency's usual
/// ending; the others force one where the currency has decimals.
enum PriceRounding: String, CaseIterable, Codable, Hashable, Sendable {
    case auto
    case ninetyNine
    case ninety
    case round

    /// The segmented control's label: Auto, .99, .90, Round.
    var title: String {
        switch self {
        case .auto: "Auto"
        case .ninetyNine: ".99"
        case .ninety: ".90"
        case .round: "Round"
        }
    }

    /// The ending to snap to in a currency. Currencies without decimals keep
    /// their usual ending for .99 and .90, and use round numbers for Round.
    func ending(forCurrency code: String) -> PriceEnding {
        let preferred = PriceEnding.preferred(forCurrency: code)
        let hasDecimals = CurrencyFormat.forCurrency(code).decimals > 0
        switch self {
        case .auto: return preferred
        case .ninetyNine: return hasDecimals ? .ninetyNine : preferred
        case .ninety: return hasDecimals ? .ninety : preferred
        case .round: return hasDecimals ? .wholeUnits : .round
        }
    }
}
