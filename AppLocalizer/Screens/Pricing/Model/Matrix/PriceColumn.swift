//
//  PriceColumn.swift
//  AppLocalizer
//

import Foundation

/// Every column the price matrix can show. Presets pick a few; the table
/// header's context menu can hide or show any of them.
enum PriceColumn: String, CaseIterable, Hashable, Sendable {
    case territory
    case region
    case currency
    case current
    case proceeds
    case dollars
    case equalized
    case feelsLike
    case suggested
    case reason
    case factor
    case source
    case proposed
    case change
    case status
    case pricing

    /// The ID `TableColumnCustomization` stores visibility under.
    var customizationID: String { "pricing.column." + rawValue }
}
