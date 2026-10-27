//
//  PricingProduct.swift
//  AppLocalizer
//

import Foundation

/// One subscription or in-app purchase in the section bar's browser.
struct PricingProduct: Identifiable, Hashable, Sendable {
    /// App Store Connect's resource ID, the one price changes refer to.
    var id: String
    var name: String
    var productID: String
    var period: SubscriptionPeriod?
    var isInAppPurchase: Bool
    /// The in-app purchase type in words (“Non-consumable”), or nil for subscriptions.
    var inAppPurchaseType: String?
    /// Apple's review state in words, such as “Approved”.
    var reviewState: String
    /// The price in the base territory, nil until it's known.
    var basePrice: Decimal?
    var baseCurrencyCode = "USD"

    /// “1 year” for subscriptions, the type for in-app purchases.
    var durationText: String {
        period?.title ?? inAppPurchaseType ?? String(localized: "In-app purchase")
    }

    /// The base price as the browser and section bar show it (“$39.99”).
    var basePriceText: String? {
        basePrice.map { CurrencyFormat.format($0, currency: baseCurrencyCode) }
    }

    /// The section bar's second line: “lumen.plus.annual · 1 year · Approved · base $39.99”.
    var subtitle: String {
        var parts = [productID, durationText, reviewState]
        if let basePriceText { parts.append(String(localized: "base \(basePriceText)")) }
        return parts.joined(separator: " · ")
    }
}
