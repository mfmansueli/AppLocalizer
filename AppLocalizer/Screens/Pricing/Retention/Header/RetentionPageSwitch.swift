//
//  RetentionPageSwitch.swift
//  AppLocalizer
//

import SwiftUI

/// Prices | Retention, with Retention tagged New. On both pages, so the
/// person can go back and forth.
struct RetentionPageSwitch: View {
    @Binding var page: PricingPage

    var body: some View {
        RetentionSegmentedControl(
            label: String(localized: "Pricing page"),
            segments: [
                RetentionSegment(value: .prices, title: PricingPage.prices.title, identifier: "pricing.page.prices"),
                RetentionSegment(
                    value: .retention, title: PricingPage.retention.title, badge: String(localized: "New"), identifier: "pricing.page.retention"
                ),
            ],
            selection: $page,
            identifier: "pricing.page"
        )
    }
}
