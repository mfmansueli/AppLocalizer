//
//  PricingRowBuilder.swift
//  AppLocalizer
//

import Foundation

/// Turns a product's price sheet and the strategy into matrix rows: one per
/// territory the product is sold in, with its suggestion and strategy price.
/// Suggestions depend only on the sheet, so callers keep them while the
/// strategy changes and only the strategy prices are worked out again.
struct PricingRowBuilder {
    let catalog: TerritoryCatalog
    let calculator: PriceCalculator
    let sheet: ProductPriceSheet
    let strategy: PricingStrategy
    let showsSuggestions: Bool
    /// The push has a start date (`PriceSchedule`).
    var isScheduled = false

    func rows(queued: [String: QueuedPrice] = [:]) -> [PricingRow] {
        rows(recommendations: recommendations(), queued: queued)
    }

    /// The suggestion per territory, or none while Pricing keeps your prices.
    func recommendations() -> [String: Recommendation] {
        guard showsSuggestions else { return [:] }
        let recommender = PriceRecommender(calculator: calculator, baseTerritoryID: sheet.baseTerritoryID)
        var result: [String: Recommendation] = [:]
        for territory in catalog.territories {
            guard let input = input(for: territory) else { continue }
            let recommendation = recommender.recommend(input, evidence: sheet.sales.evidence(for: territory.id))
            result[territory.id] = Self.explainingSales(recommendation, sheet.sales.availability)
        }
        return result
    }

    func rows(recommendations: [String: Recommendation], queued: [String: QueuedPrice]) -> [PricingRow] {
        var effective = strategy
        effective.baseTerritoryID = sheet.baseTerritoryID
        return catalog.territories.compactMap { territory in
            guard let price = sheet.prices[territory.id], let input = input(for: territory) else { return nil }
            return PricingRow(
                territory: territory,
                current: price.current,
                equalized: price.equalized.customerPrice,
                equalizationMultiplier: price.equalizationMultiplier,
                isBase: territory.id == sheet.baseTerritoryID,
                recommendation: recommendations[territory.id],
                calculation: calculator.calculate(input, strategy: effective),
                usesCustomStrategy: strategy.isCustom,
                pageViews: sheet.sales.pageViews(in: territory.id),
                queued: queued[territory.id],
                isScheduled: isScheduled
            )
        }
    }

    func input(for territory: Territory) -> PriceCalculationInput? {
        guard let price = sheet.prices[territory.id] else { return nil }
        return PriceCalculationInput(
            territory: territory,
            basePrice: sheet.basePrice,
            equalizedPrice: price.equalized.customerPrice,
            ladder: sheet.ladder(for: territory, commission: calculator.commission),
            currentPrice: price.current.customerPrice,
            equalizationMultiplier: price.equalizationMultiplier
        )
    }

    /// The engine says the key's role can't read sales; when AppLocalizer
    /// simply doesn't read them, say that instead.
    private static func explainingSales(_ recommendation: Recommendation, _ availability: PricingSalesData.Availability) -> Recommendation {
        guard availability == .notRead else { return recommendation }
        var copy = recommendation
        copy.basis = recommendation.basis.map { line in
            line.hasPrefix("Sales:") ? String(localized: "Sales: not read, so purchasing power alone") : line
        }
        return copy
    }
}
