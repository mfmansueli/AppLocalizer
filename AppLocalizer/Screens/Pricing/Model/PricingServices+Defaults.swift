//
//  PricingServices+Defaults.swift
//  AppLocalizer
//

import Foundation

/// Fallbacks for services that only feed the overview, such as the test
/// doubles that count summary fetches: they have no catalog to price. The
/// live services use the last three too, since AppLocalizer doesn't read
/// offers, subscribers or sales from App Store Connect yet.
extension PricingServices {
    func catalog(for _: StoreApp) async throws -> PricingCatalog {
        .empty
    }

    func priceSheet(for product: PricingProduct, commission _: Commission) async throws -> ProductPriceSheet {
        throw AppStoreConnectError.notFound(detail: String(localized: "No prices for \(product.name)."))
    }

    func ladders(for _: PricingProduct, territoryIDs _: [String], commission _: Commission) async throws -> [String: PricePointLadder] {
        [:]
    }

    /// The snapshot bundled with the app.
    func indexSnapshot() -> PriceIndexSnapshot {
        (try? PriceIndexSnapshot.bundled()) ?? .empty
    }

    /// Offers aren't read from App Store Connect yet.
    func offers(for _: PricingProduct) async throws -> [SubscriptionOffer] {
        []
    }

    /// Subscriber counts need Sales and Trends, which AppLocalizer doesn't read yet.
    func subscribers(for _: PricingProduct) async throws -> [String: Int]? {
        nil
    }

    /// Results need Sales and Trends and App Analytics, which AppLocalizer doesn't read yet.
    func salesComparison(for _: PricingProduct, territoryIDs _: [String], changedOn _: Date) async throws -> [String: SalesComparison]? {
        nil
    }
}
