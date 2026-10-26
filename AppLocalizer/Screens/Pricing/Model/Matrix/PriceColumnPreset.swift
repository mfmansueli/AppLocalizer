//
//  PriceColumnPreset.swift
//  AppLocalizer
//

import Foundation

/// The Columns menu. Seventeen columns don't fit at 1200 pt, so each preset
/// shows the ones a task needs; Automatic follows the mode and the inspector.
enum PriceColumnPreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case automatic
    case suggestions
    case priceIndex
    case pricesAndProceeds
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: String(localized: "Automatic")
        case .suggestions: String(localized: "Suggestions")
        case .priceIndex: String(localized: "Price index")
        case .pricesAndProceeds: String(localized: "Prices and proceeds")
        case .all: String(localized: "All columns")
        }
    }

    /// The preset Automatic stands for right now.
    static func resolved(_ preset: PriceColumnPreset, isKeepingPrices: Bool, isInspectorOpen: Bool) -> PriceColumnPreset {
        guard preset == .automatic else { return preset }
        if isKeepingPrices { return .pricesAndProceeds }
        return isInspectorOpen ? .priceIndex : .suggestions
    }

    var columns: [PriceColumn] {
        switch self {
        case .automatic, .suggestions:
            [.territory, .current, .feelsLike, .suggested, .reason, .proposed, .change, .status]
        case .priceIndex:
            [.territory, .current, .equalized, .factor, .source, .proposed, .change]
        case .pricesAndProceeds:
            [.territory, .region, .currency, .current, .proceeds, .dollars, .equalized, .pricing]
        case .all:
            PriceColumn.allCases
        }
    }
}
