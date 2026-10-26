//
//  PriceIndexSource.swift
//  AppLocalizer
//

import Foundation

/// A purchasing-power source a strategy can price by. Edition details (date,
/// badge, newer edition) live in `PriceIndexEdition`, inside the snapshot.
enum PriceIndexSource: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case bigMac
    case worldBank
    case imf
    case custom

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bigMac: "Big Mac Index"
        case .worldBank: "World Bank PPP price level"
        case .imf: "IMF implied PPP rate"
        case .custom: "Custom index"
        }
    }

    /// For "Region median of World Bank" in the fallback chain.
    var shortName: String {
        switch self {
        case .bigMac: "Big Mac"
        case .worldBank: "World Bank"
        case .imf: "IMF"
        case .custom: "custom index"
        }
    }

    var publisher: String {
        switch self {
        case .bigMac: "The Economist"
        case .worldBank: "World Bank"
        case .imf: "International Monetary Fund"
        case .custom: "Imported CSV"
        }
    }

    /// The index picker's one-line description.
    var summary: String {
        switch self {
        case .bigMac:
            "The raw index, not GDP-adjusted. Easy to explain; few countries and milder discounts. "
                + "The euro area is one entry shared by 21 territories."
        case .worldBank:
            "Price level ratio of PPP conversion factor to market exchange rate. Broadest coverage and deeper discounts "
                + "in emerging markets; runs a year or two behind."
        case .imf:
            "Implied PPP conversion rate divided by the market rate. Broad coverage, updated every April and October."
        case .custom:
            "A CSV of territory code → factor, or a local reference price. Unmatched codes are listed when you import."
        }
    }

    var sourceURL: URL? {
        switch self {
        case .bigMac: URL(string: "https://www.economist.com/big-mac-index")
        case .worldBank: URL(string: "https://data.worldbank.org/indicator/PA.NUS.PPPC.RF")
        case .imf: URL(string: "https://www.imf.org/external/datamapper/PPPEX@WEO")
        case .custom: nil
        }
    }
}
