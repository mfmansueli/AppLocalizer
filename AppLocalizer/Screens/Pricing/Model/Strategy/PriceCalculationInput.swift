//
//  PriceCalculationInput.swift
//  AppLocalizer
//

import Foundation

/// One territory's numbers for `PriceCalculator`.
struct PriceCalculationInput: Sendable {
    var territory: Territory
    /// The subscription's price in the base territory, e.g. $39.99.
    var basePrice: Decimal
    /// Apple's equalized local price for `basePrice`, e.g. R$ 219,90.
    var equalizedPrice: Decimal
    /// Local units per unit of the base currency in Apple's equalization,
    /// e.g. 5.5 for Brazil. Converts the floor, ceiling, minimum proceeds and
    /// "feels like". Defaults to equalized ÷ base.
    var equalizationMultiplier: Decimal
    var ladder: PricePointLadder
    /// What the territory charges today, for "never raise" and suggestions.
    var currentPrice: Decimal?

    init(
        territory: Territory,
        basePrice: Decimal,
        equalizedPrice: Decimal,
        ladder: PricePointLadder,
        currentPrice: Decimal? = nil,
        equalizationMultiplier: Decimal? = nil
    ) {
        self.territory = territory
        self.basePrice = basePrice
        self.equalizedPrice = equalizedPrice
        self.ladder = ladder
        self.currentPrice = currentPrice
        self.equalizationMultiplier = equalizationMultiplier ?? (basePrice > 0 ? equalizedPrice / basePrice : 1)
    }
}
