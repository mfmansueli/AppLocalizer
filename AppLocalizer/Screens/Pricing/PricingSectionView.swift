//
//  PricingSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The Subscription Pricing section of an app's workspace (⌘2).
struct PricingSectionView: View {
    let app: StoreApp
    let services: any PricingServices

    var body: some View {
        ContentUnavailableView("Subscription Pricing", systemImage: "tag", description: Text("Coming soon."))
            .accessibilityIdentifier("workspace.subscriptionPricing")
    }
}
