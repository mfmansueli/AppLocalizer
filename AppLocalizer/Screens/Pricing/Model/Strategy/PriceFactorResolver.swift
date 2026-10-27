//
//  PriceFactorResolver.swift
//  AppLocalizer
//

import Foundation

/// Walks a strategy's fallback chain to find each territory's factor:
/// factor = territory's price level ÷ base territory's price level. A source
/// with no value for the base territory is taken as already relative to it.
struct PriceFactorResolver: Sendable {
    let snapshot: PriceIndexSnapshot
    /// Raw region medians per source, computed once.
    private let medians: [PriceIndexSource: [TerritoryRegion: Decimal]]

    init(snapshot: PriceIndexSnapshot, catalog: TerritoryCatalog) {
        self.snapshot = snapshot
        var medians: [PriceIndexSource: [TerritoryRegion: Decimal]] = [:]
        for source in snapshot.indices.keys {
            medians[source] = snapshot.regionMedians(of: source, catalog: catalog)
        }
        self.medians = medians
    }

    /// The first link of the chain with data. The chosen index's region
    /// median falls back to World Bank's when the index has nothing in that
    /// region; equalized (factor 1) is the last resort.
    func resolve(_ territory: Territory, strategy: PricingStrategy) -> ResolvedFactor {
        let base = strategy.baseTerritoryID
        for step in strategy.resolutionChain {
            switch step {
            case let .index(source):
                if let factor = factor(source, territoryID: territory.id, baseTerritoryID: base) {
                    let provenance = PriceProvenance(
                        kind: .index(source),
                        isFallback: source != strategy.indexSource,
                        edition: snapshot.index(source)?.edition
                    )
                    return ResolvedFactor(factor: factor, provenance: provenance)
                }
            case .regionMedian:
                let median = regionMedian(strategy.indexSource, region: territory.region, baseTerritoryID: base)
                    ?? regionMedian(.worldBank, region: territory.region, baseTerritoryID: base)
                if let median {
                    let provenance = PriceProvenance(kind: .regionMedian(strategy.indexSource), isFallback: true)
                    return ResolvedFactor(factor: median, provenance: provenance)
                }
            case .equalized:
                return Self.equalizedFallback
            }
        }
        return Self.equalizedFallback
    }

    /// A source's factor for a territory, relative to the base territory.
    /// Nil when either has no value.
    func factor(_ source: PriceIndexSource, territoryID: String, baseTerritoryID: String) -> Decimal? {
        guard let level = snapshot.level(source, territoryID: territoryID),
              let baseLevel = baseLevel(source, baseTerritoryID: baseTerritoryID)
        else { return nil }
        return level / baseLevel
    }

    /// A source's median factor in a region, relative to the base territory.
    func regionMedian(_ source: PriceIndexSource, region: TerritoryRegion, baseTerritoryID: String) -> Decimal? {
        guard let median = medians[source]?[region],
              let baseLevel = baseLevel(source, baseTerritoryID: baseTerritoryID)
        else { return nil }
        return median / baseLevel
    }

    /// A source without a value for the base territory (a custom CSV that
    /// leaves the base out) is taken as already relative to it.
    private func baseLevel(_ source: PriceIndexSource, baseTerritoryID: String) -> Decimal? {
        guard snapshot.index(source) != nil else { return nil }
        guard let level = snapshot.level(source, territoryID: baseTerritoryID) else { return 1 }
        return level > 0 ? level : nil
    }

    private static let equalizedFallback = ResolvedFactor(
        factor: 1,
        provenance: PriceProvenance(kind: .equalized, isFallback: true)
    )
}
