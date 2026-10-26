//
//  PricingServices.swift
//  AppLocalizer
//

import Foundation

/// What the Subscription Pricing section needs from outside itself. `LivePricingServices`
/// talks to App Store Connect; tests and DEBUG scenes use canned data.
@MainActor
protocol PricingServices {
    /// The numbers the overview cards and the sidebar show for one app.
    func summary(for app: StoreApp) async throws -> PricingSummary

    /// The app's subscription groups and in-app purchases, with base prices.
    func catalog(for app: StoreApp) async throws -> PricingCatalog

    /// One product's prices in every territory, with equalized prices and
    /// whatever ladders and sales evidence are already at hand.
    func priceSheet(for product: PricingProduct, commission: Commission) async throws -> ProductPriceSheet

    /// Apple's price point ladders for a few territories, by territory ID.
    func ladders(for product: PricingProduct, territoryIDs: [String], commission: Commission) async throws -> [String: PricePointLadder]

    /// The price indices strategies draw on: the bundled snapshot, plus any
    /// custom index the scene starts with.
    func indexSnapshot() -> PriceIndexSnapshot
}
