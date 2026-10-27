//
//  DebugPricingCatalog.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The sample apps' subscription groups and in-app purchases, built from the
/// overview's canned summaries so both always agree. Lumen's products carry
/// the subscription IDs the canned review data uses.
enum DebugPricingCatalog {
    static let lumenMonthlyID = "6450100001"
    static let lumenAnnualID = "6450100002"
    static let lumenLifetimeID = "6450100003"

    static func catalog(for appID: StoreApp.ID) -> PricingCatalog {
        let summary = DebugSummaries.pricing(for: appID)
        let subscriptions = summary.products.filter { !$0.isInAppPurchase }.map { product(from: $0, appID: appID) }
        let purchases = summary.products.filter(\.isInAppPurchase).map { product(from: $0, appID: appID) }
        var groups: [PricingProductGroup] = []
        if let first = subscriptions.first {
            let name = first.name.split(separator: " ").dropLast().joined(separator: " ")
            groups.append(PricingProductGroup(id: "group." + first.productID, name: name, isInAppPurchases: false, products: subscriptions))
        }
        if !purchases.isEmpty {
            groups.append(PricingProductGroup(id: "inAppPurchases", name: String(localized: "In-App Purchases"), isInAppPurchases: true, products: purchases))
        }
        return PricingCatalog(groups: groups)
    }

    private static func product(from summary: PricingSummary.Product, appID: StoreApp.ID) -> PricingProduct {
        PricingProduct(
            id: appID == DebugFixtures.AppID.lumen ? lumenID(for: summary.productID) : summary.id,
            name: summary.name,
            productID: summary.productID,
            period: period(for: summary.duration),
            isInAppPurchase: summary.isInAppPurchase,
            inAppPurchaseType: summary.isInAppPurchase ? summary.duration : nil,
            reviewState: String(localized: "Approved"),
            basePrice: summary.basePrice.flatMap(CurrencyFormat.usd.parse)
        )
    }

    private static func lumenID(for productID: String) -> String {
        if productID.hasSuffix("monthly") { return lumenMonthlyID }
        if productID.hasSuffix("annual") { return lumenAnnualID }
        return lumenLifetimeID
    }

    private static func period(for duration: String) -> SubscriptionPeriod? {
        switch duration {
        case "1 month": .oneMonth
        case "1 year": .oneYear
        default: nil
        }
    }
}
#endif
