//
//  PricingProductsView.swift
//  AppLocalizer
//

import SwiftUI

/// Pricing's Prices page: the header, the price suggestions with Accept
/// All n, a card per product, and "What people pay" beside them (under them
/// when the window is narrow).
struct PricingProductsView: View {
    @Bindable var viewModel: PricingViewModel

    @State private var width: CGFloat = 0
    /// Nil in previews and scenes without the app's gate.
    @Environment(ProGate.self) private var pro: ProGate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                PricingHeader(viewModel: viewModel)
                if viewModel.openPriceSuggestionCount > 0 {
                    banner
                }
                let isWide = width >= 560 + 256 + Spacing.large
                let layout = isWide
                    ? AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.large))
                    : AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.large))
                layout {
                    cards
                    PricingWhatPeoplePay(viewModel: viewModel)
                }
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.large)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 - 2 * Spacing.xLarge }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("pricing.products")
    }

    private var banner: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "sparkles")
                .foregroundStyle(Palette.machineTranslated)
                .accessibilityHidden(true)
            Text(viewModel.priceSuggestionsBannerText)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                let countries = viewModel.productCards.reduce(0) { $0 + $1.suggestedCount }
                pro.require(.recommendedPrices(countries: countries)) {
                    Task { await viewModel.acceptAllPriceSuggestions() }
                }
            } label: {
                HStack(spacing: Spacing.xSmall) {
                    Text("Accept All \(viewModel.openPriceSuggestionCount)")
                    if pro.isFree { ProChip() }
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("pricing.acceptAll")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, 10)
        .background(Palette.machineTranslatedTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.suggestionsBanner")
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ForEach(viewModel.catalog?.products ?? []) { product in
                if let card = viewModel.card(for: product) {
                    PricingProductCardView(
                        card: card,
                        isExpanded: viewModel.expandedProductID == product.id,
                        onToggleCountries: { viewModel.toggleCountries(productID: product.id) },
                        onDismiss: { viewModel.dismissPriceSuggestion(productID: product.id) },
                        onAccept: {
                            // Prices for many countries at once are Pro's;
                            // one country's stays free.
                            let accept = { _ = Task { await viewModel.acceptPriceSuggestion(productID: product.id) } }
                            if card.suggestedCount > 1 {
                                pro.require(.recommendedPrices(countries: card.suggestedCount), then: accept)
                            } else {
                                accept()
                            }
                        },
                        onOpen: { Task { await viewModel.openDetails(productID: product.id) } }
                    )
                } else if let message = viewModel.productErrors[product.id] {
                    unavailable(product, message: message)
                } else {
                    placeholder(product)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    private func placeholder(_ product: PricingProduct) -> some View {
        HStack(spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name).font(.headline)
                Text(product.productID).font(.caption).foregroundStyle(Palette.label2)
            }
            Spacer()
            ProgressView().controlSize(.small)
        }
        .padding(14)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(product.name), prices loading"))
    }

    private func unavailable(_ product: PricingProduct, message: String) -> some View {
        HStack(spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name).font(.headline)
                Text(message).font(.caption).foregroundStyle(Palette.label2).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button("Edit Prices…") { Task { await viewModel.openDetails(productID: product.id) } }
                .buttonStyle(.link)
                .controlSize(.small)
        }
        .padding(14)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
    }
}
