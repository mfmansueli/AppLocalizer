//
//  PricingWhatPeoplePay.swift
//  AppLocalizer
//

import SwiftUI

/// Beside the products: the In-App Purchases list as the App Store shows it
/// in one country, now or with the suggestions (and what's queued).
struct PricingWhatPeoplePay: View {
    @Bindable var viewModel: PricingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("What people pay")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("Prices", selection: $viewModel.showsSuggestedPrices) {
                    Text("Now").tag(false)
                    Text("Suggested").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
                .accessibilityIdentifier("pricing.pay.mode")
            }
            FlowLayout(spacing: Spacing.xxSmall) {
                ForEach(territories) { territory in
                    chip(territory)
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("App Store · \(territory?.name ?? "")")
                    .font(.caption2)
                    .foregroundStyle(Palette.label2)
                Text("In-App Purchases")
                    .font(.subheadline.weight(.semibold))
                ForEach(rows, id: \.id) { row in
                    HStack(spacing: Spacing.small) {
                        Text(row.name)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(row.price)
                            .monospacedDigit()
                            .foregroundStyle(Palette.label2)
                            .modifier(AppStorePreviewHighlight(isOn: row.isSuggested))
                    }
                    .font(.callout)
                    .accessibilityElement(children: .combine)
                }
                if rows.isEmpty {
                    Text("Prices are loading…")
                        .font(.caption)
                        .foregroundStyle(Palette.label3)
                }
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            Text("Prices as the App Store shows them, with tax. Apple adjusts equalized prices when exchange rates move; prices you set stay as set.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 256)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.pay")
    }

    private var territories: [Territory] { viewModel.payTerritories }

    private var territory: Territory? {
        territories.first { $0.id == viewModel.payTerritoryID } ?? territories.first
    }

    private func chip(_ territory: Territory) -> some View {
        let isSelected = territory.id == self.territory?.id
        return Button {
            viewModel.payTerritoryID = territory.id
        } label: {
            Text(territory.alpha2 == "US" ? String(localized: "U.S.") : territory.name)
                .font(.caption)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 3)
                .foregroundStyle(isSelected ? Color.white : Palette.label)
                .background(isSelected ? Palette.accent : Palette.fill2, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("pricing.pay.country.\(territory.id)")
    }

    private struct Row {
        var id: String
        var name: String
        var price: String
        var isSuggested: Bool
    }

    private var rows: [Row] {
        guard let territory else { return [] }
        return viewModel.productCards.compactMap { card in
            guard let price = card.prices[territory.id] else { return nil }
            let shows = viewModel.showsSuggestedPrices && price.next != nil
            return Row(id: card.id, name: card.product.name, price: shows ? price.next ?? price.now : price.now, isSuggested: shows)
        }
    }
}
