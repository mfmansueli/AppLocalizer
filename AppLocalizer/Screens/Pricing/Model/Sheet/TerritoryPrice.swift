//
//  TerritoryPrice.swift
//  AppLocalizer
//

import Foundation

/// One territory's price for a product today, and the price Apple's
/// equalization would give it for the current base price.
struct TerritoryPrice: Hashable, Sendable {
    var territoryID: String
    var current: PricePoint
    var equalized: PricePoint
    /// Local currency per unit of base price, the ratio equalization applies.
    var equalizationMultiplier: Decimal

    /// Whether someone set this territory by hand instead of letting Apple equalize it.
    var isCustom: Bool {
        (current.customerPrice - equalized.customerPrice).magnitude > Decimal(1) / 1000
    }
}
