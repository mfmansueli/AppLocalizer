//
//  DebugPricingServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `PricingServices` for DEBUG scenes: the sample apps' canned data, or
/// `error`. Never contacts App Store Connect.
@MainActor
struct DebugPricingServices: PricingServices {
    var error: AppStoreConnectError?

    func summary(for app: StoreApp) async throws -> PricingSummary {
        if let error { throw error }
        return DebugSummaries.pricing(for: app.id)
    }
}
#endif
