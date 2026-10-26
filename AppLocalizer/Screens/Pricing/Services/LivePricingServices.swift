//
//  LivePricingServices.swift
//  AppLocalizer
//

import Foundation

/// The real `PricingServices`, backed by App Store Connect.
@MainActor
struct LivePricingServices: PricingServices {
    let client: AppStoreConnectClient

    func summary(for _: StoreApp) async throws -> PricingSummary {
        throw AppStoreConnectError.notFound(detail: String(localized: "Subscription Pricing isn't available yet."))
    }
}
