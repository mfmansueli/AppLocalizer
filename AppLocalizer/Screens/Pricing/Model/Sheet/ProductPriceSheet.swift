//
//  ProductPriceSheet.swift
//  AppLocalizer
//

import Foundation

/// Everything the matrix needs about one product's prices: today's price
/// and the equalized price per territory, Apple's price point ladders, and
/// the sales evidence behind suggestions.
struct ProductPriceSheet: Sendable {
    var productID: String
    var baseTerritoryID: String
    var basePrice: Decimal
    var prices: [String: TerritoryPrice]
    /// Ladders by territory. Until Apple's real ladder arrives, a territory has
    /// one simulated from its equalization multiplier, without point IDs.
    var ladders: [String: PricePointLadder]
    /// Territories whose ladder is Apple's own, so their points can be pushed.
    var exactLadderIDs: Set<String>
    var sales: PricingSalesData

    init(
        productID: String,
        baseTerritoryID: String,
        basePrice: Decimal,
        prices: [String: TerritoryPrice],
        ladders: [String: PricePointLadder] = [:],
        exactLadderIDs: Set<String> = [],
        sales: PricingSalesData = .notRead
    ) {
        self.productID = productID
        self.baseTerritoryID = baseTerritoryID
        self.basePrice = basePrice
        self.prices = prices
        self.ladders = ladders
        self.exactLadderIDs = exactLadderIDs
        self.sales = sales
    }

    func ladder(for territory: Territory, commission: Commission) -> PricePointLadder {
        if let ladder = ladders[territory.id] { return ladder }
        let multiplier = prices[territory.id]?.equalizationMultiplier ?? 1
        return SimulatedPriceLadder.make(territory: territory, equalizationMultiplier: multiplier, commission: commission)
    }

    /// Territories that still need Apple's ladder before a price there can be pushed.
    func missingLadders(in territoryIDs: some Sequence<String>) -> [String] {
        territoryIDs.filter { !exactLadderIDs.contains($0) && prices[$0] != nil }
    }

    /// Adds Apple's ladders as they arrive.
    mutating func merge(_ newLadders: [String: PricePointLadder]) {
        for (territoryID, ladder) in newLadders where !ladder.isEmpty {
            ladders[territoryID] = ladder
            exactLadderIDs.insert(territoryID)
            // The current and equalized points now carry Apple's IDs too.
            if var price = prices[territoryID] {
                price.current = ladder.point(at: price.current.customerPrice) ?? price.current
                price.equalized = ladder.point(at: price.equalized.customerPrice) ?? price.equalized
                prices[territoryID] = price
            }
        }
    }
}
