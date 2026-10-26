//
//  PricingStrategy.swift
//  AppLocalizer
//

import Foundation

/// Everything the strategy inspector sets. The base price itself belongs to
/// each subscription and is passed with `PriceCalculationInput`.
///
/// Fractions are 0…1 (floor 0.30 = 30% of the base price).
struct PricingStrategy: Hashable, Sendable, Codable {
    var method: PricingMethod = .recommended
    /// App Store Connect ID of the base territory (`USA`).
    var baseTerritoryID = "USA"
    var indexSource: PriceIndexSource = .worldBank
    /// Tried in order after `indexSource`.
    var fallback: [FallbackStep] = [.regionMedian, .equalized]
    /// 0 = equalized, 1 = the full index.
    var intensity: Decimal = 1
    /// Never below this share of the base price.
    var floor = Decimal(30) / 100
    /// Never above this share of the base price; only when premiums are
    /// allowed (`discountOnly` off).
    var ceiling = Decimal(150) / 100
    /// Minimum proceeds per territory, in the base currency; nil = off.
    var minimumProceeds: Decimal?
    /// Never above Apple's equalized price.
    var discountOnly = true
    var tiersEnabled = false
    var tiers = PricingTiers.standard
    /// For `.regionalTiers`: the factor per region.
    var regionMultipliers: [TerritoryRegion: Decimal] = [
        .americas: Decimal(70) / 100,
        .europe: Decimal(90) / 100,
        .asiaPacific: Decimal(70) / 100,
        .africaMiddleEast: Decimal(60) / 100,
    ]
    /// Territories that stay at the equalized price, e.g. Japan.
    var excludedTerritoryIDs: Set<String> = []
    var rounding: PriceRounding = .auto
    /// Never above the current price.
    var neverRaise = false

    /// World Bank PPP at 100%, floor 30%, discounts only.
    static let recommended = PricingStrategy()

    var isRecommended: Bool { method == .recommended }

    /// "Custom" in the inspector, with Back to Recommended.
    var isCustom: Bool { !isRecommended }

    /// The chosen index, then the fallbacks without repeating it.
    var resolutionChain: [FallbackStep] {
        [.index(indexSource)] + fallback.filter { $0 != .index(indexSource) }
    }

    func isExcluded(_ territoryID: String) -> Bool {
        excludedTerritoryIDs.contains(territoryID)
    }

    func regionMultiplier(for region: TerritoryRegion) -> Decimal {
        regionMultipliers[region] ?? 1
    }

    /// Applies an inspector edit. Like the prototype, changing anything
    /// while Recommended turns the strategy into a custom price index;
    /// picking Recommended resets everything but the base territory.
    mutating func customize(_ edit: (inout PricingStrategy) -> Void) {
        let wasRecommended = isRecommended
        var next = self
        edit(&next)
        if next.method == .recommended, !wasRecommended {
            self = Self.recommended(baseTerritoryID: next.baseTerritoryID)
            return
        }
        if next.method == .recommended, next != self { next.method = .priceIndex }
        self = next
    }

    /// Back to Recommended, keeping the base territory.
    mutating func resetToRecommended() {
        self = Self.recommended(baseTerritoryID: baseTerritoryID)
    }

    static func recommended(baseTerritoryID: String) -> PricingStrategy {
        var strategy = PricingStrategy.recommended
        strategy.baseTerritoryID = baseTerritoryID
        return strategy
    }
}
