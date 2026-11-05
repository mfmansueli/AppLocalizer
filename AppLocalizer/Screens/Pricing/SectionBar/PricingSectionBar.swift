//
//  PricingSectionBar.swift
//  AppLocalizer
//

import SwiftUI

/// Pricing's section bar: the product browser, Prices | Offers | Results,
/// the pricing mode and Customize…. With the inspector open and the window
/// narrow, the mode and Customize… wrap to a second row.
struct PricingSectionBar: View {
    @Bindable var viewModel: PricingViewModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.medium) {
                browserButton
                Spacer(minLength: Spacing.medium)
                viewPicker
                modeControls
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(spacing: Spacing.medium) {
                    browserButton
                    Spacer(minLength: Spacing.medium)
                    viewPicker
                }
                HStack(spacing: Spacing.small) { modeControls }
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .frame(minHeight: 52)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var browserButton: some View {
        if let product = viewModel.selectedProduct {
            Button {
                viewModel.isBrowserPresented.toggle()
            } label: {
                SectionBarTitle(systemImage: "tag", title: product.name, subtitle: product.subtitle, showsChevron: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "\(product.name), \(product.subtitle)"))
            .accessibilityHint(String(localized: "Shows every subscription and in-app purchase"))
            .accessibilityIdentifier("pricing.productBrowser")
            .popover(isPresented: $viewModel.isBrowserPresented, arrowEdge: .bottom) {
                if let catalog = viewModel.catalog {
                    ProductBrowserPopover(catalog: catalog, selectedID: product.id, queuedNewSubscriptions: viewModel.queuedNewSubscriptions) { product in
                        Task { await viewModel.select(productID: product.id) }
                    } onNewSubscription: {
                        viewModel.isBrowserPresented = false
                        viewModel.isNewSubscriptionSheetPresented = true
                    }
                }
            }
        } else {
            SectionBarTitle(systemImage: "tag", title: String(localized: "Subscription Pricing"))
        }
    }

    private var viewPicker: some View {
        let isPurchase = viewModel.selectedProduct?.isInAppPurchase == true
        return PricingSegmentedControl(
            label: String(localized: "View"),
            segments: PricingTab.allCases.map { tab in
                let hasNoOffers = tab == .offers && isPurchase
                return PricingSegmentedControl<PricingTab>.Segment(
                    value: tab,
                    title: tab.title,
                    label: tab.title,
                    isEnabled: !hasNoOffers,
                    help: hasNoOffers ? String(localized: "In-app purchases have no offers") : nil
                )
            },
            selection: $viewModel.tab,
            identifier: "pricing.viewPicker"
        )
        .fixedSize()
    }

    @ViewBuilder
    private var modeControls: some View {
        PricingModeMenu(viewModel: viewModel)
        if viewModel.mode != .keepPrices, viewModel.selectedProduct?.isInAppPurchase != true {
            Toggle(isOn: $viewModel.isInspectorPresented) {
                Label("Customize…", systemImage: "slider.horizontal.3")
            }
            .toggleStyle(.button)
            .keyboardShortcut("i", modifiers: [.command, .option])
            .help("Customize the pricing strategy (⌥⌘I)")
            .accessibilityIdentifier("pricing.customize")
        }
    }
}
