//
//  PricingModeCard.swift
//  AppLocalizer
//

import SwiftUI

/// The app's pricing mode and, unless prices are kept, how many territories
/// have a price that likely holds people back.
struct PricingModeCard: View {
    let mode: PricingMode
    let summary: PricingSummary
    let onReviewSuggestions: () -> Void
    let onShowSuggestions: () -> Void

    var body: some View {
        Card {
            OverviewCardTitle(title: String(localized: "Pricing · \(mode.title)"))
            if mode == .keepPrices {
                Text("Prices are kept as they are")
                    .font(.title3.weight(.semibold))
                Text("AppLocalizer won't propose price changes for this app.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.label2)
                Button("Show price suggestions", action: onShowSuggestions)
                    .buttonStyle(.link)
                    .font(.subheadline)
                    .accessibilityIdentifier("overview.showPriceSuggestions")
            } else {
                Text(heldBackTitle)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text("have a price that likely holds people back: it feels at least 25% above the \(summary.baseTerritoryName) price to someone there.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Review Suggestions", action: onReviewSuggestions)
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
            }
        }
        .accessibilityIdentifier("overview.pricingCard")
    }

    private var heldBackTitle: String {
        guard let count = summary.heldBackTerritoryCount else { return String(localized: "Not computed yet") }
        return count == 1 ? String(localized: "1 territory") : String(localized: "\(count) territories")
    }
}
