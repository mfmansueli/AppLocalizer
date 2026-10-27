//
//  PriceBulkRow.swift
//  AppLocalizer
//

import Foundation

/// One selected territory for a bulk action.
struct PriceBulkRow: Sendable {
    var territory: Territory
    var ladder: PricePointLadder
    var currentPrice: Decimal
    /// A pending proposal, which bulk actions start from when present.
    var proposedPrice: Decimal?
    var equalizedPrice: Decimal
    var equalizationMultiplier: Decimal
    /// The "feels like" factor (World Bank or region median).
    var feelsLikeFactor: Decimal

    /// What the row shows: the proposal, or the current price.
    var shownPrice: Decimal { proposedPrice ?? currentPrice }
}
