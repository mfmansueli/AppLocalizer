//
//  PriceCalculator+Inspector.swift
//  AppLocalizer
//

import Foundation

extension PriceCalculator {
    /// Current, equalized and each index's price for one territory, for the
    /// Territory tab. Each index is tried alone (no fallback, no exclusion)
    /// with the rest of the strategy kept; Recommended compares with the
    /// recommended settings.
    func compareSources(_ input: PriceCalculationInput, strategy: PricingStrategy) -> [SourceComparison] {
        let current = input.currentPrice ?? input.equalizedPrice
        var bars = [
            SourceComparison(kind: .current, title: "Current", price: current),
            SourceComparison(kind: .equalized, title: "Equalized", price: input.equalizedPrice),
        ]
        let template = strategy.isRecommended ? PricingStrategy.recommended(baseTerritoryID: strategy.baseTerritoryID) : strategy
        for source in [PriceIndexSource.bigMac, .worldBank, .imf, .custom] {
            var alone = template
            alone.method = .priceIndex
            alone.indexSource = source
            alone.fallback = []
            alone.excludedTerritoryIDs = []
            let hasData = resolver.factor(source, territoryID: input.territory.id, baseTerritoryID: strategy.baseTerritoryID) != nil
            let price = hasData ? calculate(input, strategy: alone).price.customerPrice : nil
            bars.append(SourceComparison(kind: .index(source), title: source.name, price: price))
        }
        return bars
    }

    /// "n territories use a fallback".
    func fallbackCount(strategy: PricingStrategy) -> Int {
        catalog.territories.count { resolver.resolve($0, strategy: strategy).provenance.isFallback }
    }

    /// Territories per tier (4 counts) by their resolved factor.
    func tierCounts(strategy: PricingStrategy) -> [Int] {
        var counts = Array(repeating: 0, count: strategy.tiers.thresholds.count + 1)
        for territory in catalog.territories {
            let factor = resolver.resolve(territory, strategy: strategy).factor
            counts[strategy.tiers.tierIndex(for: factor)] += 1
        }
        return counts
    }
}
