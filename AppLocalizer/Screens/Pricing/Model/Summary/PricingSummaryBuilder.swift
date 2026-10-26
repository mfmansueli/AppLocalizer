//
//  PricingSummaryBuilder.swift
//  AppLocalizer
//

import Foundation

/// Works out the overview's pricing numbers from what Pricing loads: the
/// catalog, and the price sheet of the product the overview reports on.
struct PricingSummaryBuilder {
    let catalog: PricingCatalog
    /// The reported product's prices; nil when there's nothing to compute yet.
    let sheet: ProductPriceSheet?
    var territories: TerritoryCatalog = .standard
    var snapshot: PriceIndexSnapshot = (try? PriceIndexSnapshot.bundled()) ?? .empty

    var reportedProduct: PricingProduct? {
        guard let sheet else { return nil }
        return catalog.product(id: sheet.productID)
    }

    func summary() -> PricingSummary {
        let prices = sheet.map { Array($0.prices.values) } ?? []
        let custom = prices.count(where: \.isCustom)
        return PricingSummary(
            groupCount: catalog.groups.count { !$0.isInAppPurchases },
            subscriptionCount: catalog.subscriptions.count,
            inAppPurchaseCount: catalog.inAppPurchases.count,
            products: catalog.products.map { product in
                PricingSummary.Product(
                    id: product.id,
                    name: product.name,
                    productID: product.productID,
                    duration: product.durationText,
                    basePrice: product.basePriceText,
                    isInAppPurchase: product.isInAppPurchase
                )
            },
            reportedProductName: reportedProduct.map { $0.period?.shortTitle ?? $0.name },
            equalizedTerritoryCount: prices.count - custom,
            customTerritoryCount: custom,
            heldBackTerritoryCount: heldBackCount(),
            baseTerritoryName: sheet.flatMap { territories.territory(alpha3: $0.baseTerritoryID)?.referenceName } ?? "US"
        )
    }

    /// Territories where the recommended price is well below today's: likely
    /// held back by price.
    private func heldBackCount() -> Int? {
        guard let sheet, !sheet.prices.isEmpty else { return nil }
        let builder = PricingRowBuilder(
            catalog: territories,
            calculator: PriceCalculator(catalog: territories, snapshot: snapshot),
            sheet: sheet,
            strategy: .recommended(baseTerritoryID: sheet.baseTerritoryID),
            showsSuggestions: true
        )
        return builder.rows().count(where: \.likelyHeldBack)
    }
}
