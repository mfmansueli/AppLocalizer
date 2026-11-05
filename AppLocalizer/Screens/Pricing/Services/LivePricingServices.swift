//
//  LivePricingServices.swift
//  AppLocalizer
//

import Foundation

/// The real `PricingServices`, backed by App Store Connect. Sales and Trends
/// aren't read, so live suggestions use purchasing power alone.
@MainActor
struct LivePricingServices: PricingServices {
    let client: AppStoreConnectClient
    let cache = LivePricingCache()
    var catalog = TerritoryCatalog.standard
    var baseTerritoryID = "USA"
    var today: () -> Date = { .now }

    func summary(for app: StoreApp) async throws -> PricingSummary {
        let catalog = try await catalog(for: app)
        guard let product = catalog.defaultProduct, !product.isInAppPurchase else {
            return PricingSummaryBuilder(catalog: catalog, sheet: nil).summary()
        }
        let sheet = try await priceSheet(for: product, commission: .smallBusiness)
        return PricingSummaryBuilder(catalog: catalog, sheet: sheet, territories: self.catalog).summary()
    }

    func catalog(for app: StoreApp) async throws -> PricingCatalog {
        let groups = try await client.pricedSubscriptionGroups(appID: app.id)
        let purchases = try await client.pricedInAppPurchases(appID: app.id)
        var result = LivePricingMapper.catalog(groups: groups, inAppPurchases: purchases)
        for groupIndex in result.groups.indices where !result.groups[groupIndex].isInAppPurchases {
            for productIndex in result.groups[groupIndex].products.indices {
                let product = result.groups[groupIndex].products[productIndex]
                result.groups[groupIndex].products[productIndex].basePrice = try await basePrice(of: product)
            }
        }
        return result
    }

    func priceSheet(for product: PricingProduct, commission: Commission) async throws -> ProductPriceSheet {
        guard !product.isInAppPurchase else {
            throw AppStoreConnectError.notFound(detail: String(localized: "Prices for in-app purchases aren’t shown yet."))
        }
        let prices = try await client.subscriptionPrices(subscriptionID: product.id)
        let current = LivePricingMapper.currentPrices(prices, commission: commission, today: dayString(today()))
        guard let basePointID = current[baseTerritoryID]?.appStoreConnectID else {
            throw PricingSheetError.noStartingPrice(productName: product.name)
        }
        let equalized = try await LivePricingMapper.pointsByTerritory(client.equalizations(pricePointID: basePointID), commission: commission)
        guard var sheet = LivePricingMapper.sheet(
            product: product,
            current: current,
            equalized: equalized,
            baseTerritoryID: baseTerritoryID,
            catalog: catalog,
            commission: commission
        ) else {
            throw AppStoreConnectError.unexpectedPayload
        }
        sheet.merge(cache.ladders(for: cacheKey(product, commission), territoryIDs: Array(sheet.prices.keys)))
        return sheet
    }

    func ladders(for product: PricingProduct, territoryIDs: [String], commission: Commission) async throws -> [String: PricePointLadder] {
        let key = cacheKey(product, commission)
        var result = cache.ladders(for: key, territoryIDs: territoryIDs)
        let missing = territoryIDs.filter { result[$0] == nil }
        var start = missing.startIndex
        while start < missing.endIndex {
            let end = min(start + AppStoreConnectClient.pricePointTerritoryBatch, missing.endIndex)
            let batch = Array(missing[start..<end])
            let document = try await client.subscriptionPricePoints(subscriptionID: product.id, territoryIDs: batch)
            var fetched: [String: PricePointLadder] = [:]
            for (territoryID, points) in LivePricingMapper.pointsByTerritory(document, commission: commission) {
                guard let territory = catalog.territory(alpha3: territoryID) else { continue }
                fetched[territoryID] = PricePointLadder(territoryID: territoryID, currencyCode: territory.currencyCode, points: points)
            }
            cache.store(fetched, for: key)
            result.merge(fetched) { _, new in new }
            start = end
        }
        return result
    }

    // MARK: - Private

    private func basePrice(of product: PricingProduct) async throws -> Decimal? {
        let prices = try await client.subscriptionPrices(subscriptionID: product.id, territoryID: baseTerritoryID)
        return LivePricingMapper.currentPrices(prices, commission: .standard, today: dayString(today()))[baseTerritoryID]?.customerPrice
    }

    private func cacheKey(_ product: PricingProduct, _ commission: Commission) -> String {
        product.id + "." + commission.rawValue
    }

    private func dayString(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: .gmt).year().month().day())
    }
}
