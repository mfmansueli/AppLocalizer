//
//  LivePricingMapper.swift
//  AppLocalizer
//

import Foundation

/// Turns App Store Connect's pricing responses into Pricing's model. Pure,
/// so each step is tested without a network.
enum LivePricingMapper {
    // MARK: - Catalog

    static func catalog(
        groups: PricingAPIDocument<SubscriptionGroupAttributes>,
        inAppPurchases: [PricingAPIResource<InAppPurchaseAttributes>]
    ) -> PricingCatalog {
        let included = groups.includedByKey()
        var result: [PricingProductGroup] = groups.data.map { group in
            let products = group.relatedAll("subscriptions").compactMap { identifier -> PricingProduct? in
                guard let attributes = included[identifier]?.attributes else { return nil }
                return PricingProduct(
                    id: identifier.id,
                    name: attributes.name ?? attributes.productId ?? identifier.id,
                    productID: attributes.productId ?? identifier.id,
                    period: attributes.subscriptionPeriod.flatMap(SubscriptionPeriod.init(rawValue:)),
                    isInAppPurchase: false,
                    reviewState: stateTitle(attributes.state)
                )
            }
            return PricingProductGroup(id: group.id, name: group.attributes.referenceName, isInAppPurchases: false, products: products)
        }
        if !inAppPurchases.isEmpty {
            let products = inAppPurchases.map { purchase in
                PricingProduct(
                    id: purchase.id,
                    name: purchase.attributes.name,
                    productID: purchase.attributes.productId,
                    isInAppPurchase: true,
                    inAppPurchaseType: purchaseTypeTitle(purchase.attributes.inAppPurchaseType),
                    reviewState: stateTitle(purchase.attributes.state)
                )
            }
            result.append(PricingProductGroup(id: "inAppPurchases", name: String(localized: "In-App Purchases"), isInAppPurchases: true, products: products))
        }
        return PricingCatalog(groups: result)
    }

    /// “READY_TO_SUBMIT” → “Ready to Submit”-style words for Apple's states.
    static func stateTitle(_ state: String?) -> String {
        switch state {
        case "APPROVED": String(localized: "Approved")
        case "MISSING_METADATA": String(localized: "Missing Metadata")
        case "READY_TO_SUBMIT": String(localized: "Ready to Submit")
        case "WAITING_FOR_REVIEW": String(localized: "Waiting for Review")
        case "IN_REVIEW": String(localized: "In Review")
        case "DEVELOPER_ACTION_NEEDED": String(localized: "Developer Action Needed")
        case "REJECTED": String(localized: "Rejected")
        case "REMOVED_FROM_SALE", "DEVELOPER_REMOVED_FROM_SALE": String(localized: "Removed from Sale")
        case let .some(other): other.replacingOccurrences(of: "_", with: " ").capitalized
        case nil: String(localized: "Unknown state")
        }
    }

    static func purchaseTypeTitle(_ type: String?) -> String {
        switch type {
        case "CONSUMABLE": String(localized: "Consumable")
        case "NON_CONSUMABLE": String(localized: "Non-consumable")
        case "NON_RENEWING_SUBSCRIPTION": String(localized: "Non-renewing subscription")
        default: String(localized: "In-app purchase")
        }
    }

    // MARK: - Prices

    /// Today's price per territory: of each territory's prices, the latest
    /// that has already started (no start date means since the beginning).
    static func currentPrices(
        _ document: PricingAPIDocument<SubscriptionPriceAttributes>,
        commission: Commission,
        today: String
    ) -> [String: PricePoint] {
        let included = document.includedByKey()
        var best: [String: (start: String, point: PricePoint)] = [:]
        for price in document.data {
            let start = price.attributes.startDate ?? ""
            guard start <= today,
                  let territoryID = price.related("territory")?.id,
                  let pointID = price.related("subscriptionPricePoint"),
                  let point = pricePoint(id: pointID.id, attributes: included[pointID]?.attributes, commission: commission)
            else { continue }
            if let existing = best[territoryID], existing.start > start { continue }
            best[territoryID] = (start, point)
        }
        return best.mapValues(\.point)
    }

    /// Price points grouped by territory, from a price point or equalization response.
    static func pointsByTerritory(
        _ document: PricingAPIDocument<SubscriptionPricePointAttributes>,
        commission: Commission
    ) -> [String: [PricePoint]] {
        var result: [String: [PricePoint]] = [:]
        for resource in document.data {
            guard let territoryID = resource.related("territory")?.id,
                  let point = pricePoint(id: resource.id, attributes: resource.attributes, commission: commission)
            else { continue }
            result[territoryID, default: []].append(point)
        }
        return result
    }

    /// Proceeds follow the commission: Small Business Program members earn
    /// the after-one-year rate from the start.
    static func pricePoint(id: String, attributes: SubscriptionPricePointAttributes?, commission: Commission) -> PricePoint? {
        guard let price = decimal(attributes?.customerPrice) else { return nil }
        let standard = decimal(attributes?.proceeds) ?? 0
        let reduced = decimal(attributes?.proceedsYear2) ?? standard
        return PricePoint(customerPrice: price, proceeds: commission == .smallBusiness ? reduced : standard, appStoreConnectID: id)
    }

    private static func pricePoint(id: String, attributes: PricingAPIIncluded.Attributes?, commission: Commission) -> PricePoint? {
        pricePoint(
            id: id,
            attributes: SubscriptionPricePointAttributes(
                customerPrice: attributes?.customerPrice,
                proceeds: attributes?.proceeds,
                proceedsYear2: attributes?.proceedsYear2
            ),
            commission: commission
        )
    }

    static func decimal(_ text: String?) -> Decimal? {
        text.flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
    }

    // MARK: - Sheet

    /// Joins today's prices and the equalized ones into a sheet. Ladders start
    /// simulated from each territory's equalization ratio until Apple's arrive.
    static func sheet(
        product: PricingProduct,
        current: [String: PricePoint],
        equalized: [String: [PricePoint]],
        baseTerritoryID: String,
        catalog: TerritoryCatalog,
        commission: Commission
    ) -> ProductPriceSheet? {
        guard let base = current[baseTerritoryID], base.customerPrice > 0 else { return nil }
        var prices: [String: TerritoryPrice] = [:]
        var ladders: [String: PricePointLadder] = [:]
        for (territoryID, point) in current {
            guard let territory = catalog.territory(alpha3: territoryID) else { continue }
            let equal = territoryID == baseTerritoryID ? base : equalized[territoryID]?.first ?? point
            let multiplier = equal.customerPrice / base.customerPrice
            prices[territoryID] = TerritoryPrice(territoryID: territoryID, current: point, equalized: equal, equalizationMultiplier: multiplier)
            ladders[territoryID] = SimulatedPriceLadder.make(territory: territory, equalizationMultiplier: multiplier, commission: commission)
        }
        return ProductPriceSheet(
            productID: product.id,
            baseTerritoryID: baseTerritoryID,
            basePrice: base.customerPrice,
            prices: prices,
            ladders: ladders,
            sales: PricingSalesData(availability: .notRead, baseTerritoryID: baseTerritoryID)
        )
    }
}
