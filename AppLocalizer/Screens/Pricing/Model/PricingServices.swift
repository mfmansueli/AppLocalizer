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
}
