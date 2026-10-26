//
//  SimulatedPriceLadder.swift
//  AppLocalizer
//

import Foundation

/// A stand-in for Apple's ~800 price points per territory, built from the
/// design prototype's per-currency rules. For DEBUG scenes, sample data and
/// tests; the real ladders come from App Store Connect.
///
/// Like Apple's, a simulated ladder mixes endings: the currency's usual one
/// plus whatever .99, .90 and Round resolve to there, so every rounding
/// choice has points to land on.
enum SimulatedPriceLadder {
    /// The dollar range the points cover, converted with the equalization
    /// multiplier.
    static let defaultDollarRange: ClosedRange<Double> = 0.29...1000

    static func make(
        territory: Territory,
        equalizationMultiplier: Decimal,
        commission: Commission = .smallBusiness,
        dollarRange: ClosedRange<Double> = defaultDollarRange
    ) -> PricePointLadder {
        let points = prices(
            currency: territory.currencyCode,
            equalizationMultiplier: equalizationMultiplier,
            dollarRange: dollarRange
        ).map { price in
            PricePoint(
                customerPrice: price,
                proceeds: commission.proceeds(customerPrice: price, taxRate: territory.taxRate).rounded(scale: 2)
            )
        }
        return PricePointLadder(territoryID: territory.id, currencyCode: territory.currencyCode, points: points)
    }

    /// Every grid price for the currency's endings within the range, ascending.
    static func prices(
        currency: String,
        equalizationMultiplier: Decimal,
        dollarRange: ClosedRange<Double> = defaultDollarRange
    ) -> [Decimal] {
        let multiplier = equalizationMultiplier.doubleValue
        let low = dollarRange.lowerBound * multiplier
        let high = dollarRange.upperBound * multiplier
        guard low > 0, high >= low else { return [] }
        let endings = Set(PriceRounding.allCases.map { $0.ending(forCurrency: currency) })
        var cents = Set<Int64>()
        for ending in endings {
            // Sampling at a quarter of the grid step reaches every grid price.
            var value = low
            while value <= high {
                let price = ending.gridSnap(value)
                if price > 0 { cents.insert(Int64((price * 100).rounded())) }
                value += ending.gridStep(around: value) / 4
            }
        }
        return cents.sorted().map { Decimal($0) / 100 }
    }
}
