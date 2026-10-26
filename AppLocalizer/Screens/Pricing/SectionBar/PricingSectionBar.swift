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

    @State private var view = PricingView.prices

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

    private enum PricingView: Hashable {
        case prices
        case offers
        case results
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
                    ProductBrowserPopover(catalog: catalog, selectedID: product.id) { product in
                        Task { await viewModel.select(productID: product.id) }
                    }
                }
            }
        } else {
            SectionBarTitle(systemImage: "tag", title: String(localized: "Subscription Pricing"))
        }
    }

    private var viewPicker: some View {
        let later = String(localized: "Arrives in a later update")
        let isPurchase = viewModel.selectedProduct?.isInAppPurchase == true
        return PricingSegmentedControl(
            label: String(localized: "View"),
            segments: [
                .init(value: PricingView.prices, title: String(localized: "Prices"), label: String(localized: "Prices")),
                .init(value: .offers, title: String(localized: "Offers"), label: String(localized: "Offers"), isEnabled: false,
                      help: isPurchase ? String(localized: "In-app purchases have no offers") : later),
                .init(value: .results, title: String(localized: "Results"), label: String(localized: "Results"), isEnabled: false, help: later),
            ],
            selection: $view,
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
