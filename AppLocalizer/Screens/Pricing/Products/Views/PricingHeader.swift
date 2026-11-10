//
//  PricingHeader.swift
//  AppLocalizer
//

import SwiftUI

/// The top of Pricing's Prices page: what Pricing changes, Prices |
/// Retention with the Prices count, Add Subscription…, and More (the
/// pricing mode, Customize…, every price of a product, and Restore
/// Dismissed).
struct PricingHeader: View {
    @Bindable var viewModel: PricingViewModel

    var body: some View {
        SectionHeader(
            systemImage: "tag",
            tint: Palette.sectionPricing,
            title: String(localized: "Pricing"),
            subtitle: subtitle
        ) {
            BadgedSegments(
                label: String(localized: "Pricing"),
                options: [
                    (value: PricingPage.prices, title: PricingPage.prices.title, count: viewModel.openPriceSuggestionCount),
                    (value: PricingPage.retention, title: PricingPage.retention.title, count: 0),
                ],
                selection: $viewModel.page
            )
            .accessibilityIdentifier("pricing.page")
            Button {
                viewModel.isNewSubscriptionSheetPresented = true
            } label: {
                Label("Add Subscription…", systemImage: "plus")
            }
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("pricing.addSubscription")
            PricingModeMenu(viewModel: viewModel)
            moreMenu
        }
    }

    /// "What Lumen’s subscriptions and purchases cost in 175 countries and
    /// regions."
    private var subtitle: String {
        guard let count = viewModel.territoryCount else {
            return String(localized: "What \(viewModel.app.name)’s subscriptions and purchases cost in each country and region.")
        }
        return String(localized: "What \(viewModel.app.name)’s subscriptions and purchases cost in \(count) countries and regions.")
    }

    private var moreMenu: some View {
        Menu {
            if let product = viewModel.selectedProduct ?? viewModel.catalog?.defaultProduct {
                Button("Every Price of \(product.name)…") {
                    Task { await viewModel.openDetails(productID: product.id) }
                }
            }
            if viewModel.mode != .keepPrices {
                Button("Customize Pricing Strategy…") { viewModel.isInspectorPresented = true }
            }
            if viewModel.hasDismissedPriceSuggestions {
                Divider()
                Button("Restore Dismissed Suggestions") { viewModel.restoreDismissedPriceSuggestions() }
            }
        } label: {
            Label("More", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More")
        .accessibilityIdentifier("pricing.more")
    }
}
