//
//  PricingSummary.swift
//  AppLocalizer
//

import Foundation

/// What the overview's Subscriptions, Territory prices and Pricing cards and
/// the sidebar's price tag show for one app. Produced by `PricingServices`.
struct PricingSummary: Hashable, Sendable {
    /// One subscription or in-app purchase in the Subscriptions card.
    struct Product: Hashable, Sendable, Identifiable {
        var id: String
        var name: String
        var productID: String
        /// "1 month", "1 year", "Non-consumable".
        var duration: String
        /// The base territory's price, formatted ("$39.99"); nil when it has none.
        var basePrice: String?
        var isInAppPurchase: Bool
    }

    var groupCount: Int
    var subscriptionCount: Int
    var inAppPurchaseCount: Int
    var products: [Product]
    /// The product the territory numbers describe, e.g. "Annual".
    var reportedProductName: String?
    /// Territories whose price is Apple's equalized one vs set by hand or an
    /// earlier push. Both are 0 when the app sells nothing.
    var equalizedTerritoryCount: Int
    var customTerritoryCount: Int
    /// Territories whose price likely holds people back (it feels at least
    /// 25% above the base price); nil when it couldn't be computed.
    var heldBackTerritoryCount: Int?
    /// e.g. "US".
    var baseTerritoryName: String

    static let empty = PricingSummary(
        groupCount: 0,
        subscriptionCount: 0,
        inAppPurchaseCount: 0,
        products: [],
        equalizedTerritoryCount: 0,
        customTerritoryCount: 0,
        heldBackTerritoryCount: nil,
        baseTerritoryName: "US"
    )

    var sellsAnything: Bool { subscriptionCount + inAppPurchaseCount > 0 }
}
