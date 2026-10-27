//
//  PricingCatalog.swift
//  AppLocalizer
//

import Foundation

/// Everything an app sells: its subscription groups, then its in-app purchases.
struct PricingCatalog: Hashable, Sendable {
    var groups: [PricingProductGroup]

    static let empty = PricingCatalog(groups: [])

    var products: [PricingProduct] { groups.flatMap(\.products) }

    var subscriptions: [PricingProduct] { products.filter { !$0.isInAppPurchase } }

    var inAppPurchases: [PricingProduct] { products.filter(\.isInAppPurchase) }

    var isEmpty: Bool { products.isEmpty }

    func product(id: String) -> PricingProduct? {
        products.first { $0.id == id }
    }

    /// What Pricing opens on: the first annual subscription, as that's where
    /// most revenue is, else the first product.
    var defaultProduct: PricingProduct? {
        subscriptions.first { $0.period == .oneYear } ?? subscriptions.first ?? products.first
    }

    func group(containing productID: String) -> PricingProductGroup? {
        groups.first { group in group.products.contains { $0.id == productID } }
    }

    /// The other subscriptions in the same group, for “Copy from Monthly” and
    /// “Apply Strategy to Whole Group”.
    func siblings(of product: PricingProduct) -> [PricingProduct] {
        guard !product.isInAppPurchase, let group = group(containing: product.id) else { return [] }
        return group.products.filter { $0.id != product.id && !$0.isInAppPurchase }
    }
}
