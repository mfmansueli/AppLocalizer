//
//  PricingServices+Defaults.swift
//  AppLocalizer
//

import Foundation

/// Fallbacks for services that only feed the overview, such as the test
/// doubles that count summary fetches: they have no catalog to price.
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
}
