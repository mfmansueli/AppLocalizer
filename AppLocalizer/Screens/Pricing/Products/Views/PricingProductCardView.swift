//
//  PricingProductCardView.swift
//  AppLocalizer
//

import SwiftUI

/// One product on the Prices page: its name, kind and product ID, Not
/// pushed, its price in the base territory, the bar of how its prices are
/// set, and its open suggestion with Show Countries, Dismiss and Accept.
struct PricingProductCardView: View {
    let card: PricingProductCard
    let isExpanded: Bool
    let onToggleCountries: () -> Void
    let onDismiss: () -> Void
    let onAccept: () -> Void
    /// Edit Prices…: the product's matrix.
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xSmall) {
                        Text(card.product.name)
                            .font(.headline)
                            .lineLimit(1)
                        if card.hasQueuedChanges {
                            Pill(text: String(localized: "Not pushed"), style: .accent)
                                .fixedSize()
                        }
                    }
                    Text("\(card.kindText) · \(card.product.productID)")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: Spacing.small)
                if let price = card.basePrice {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(price)
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                        Text(card.baseTerritoryText)
                            .font(.caption2)
                            .foregroundStyle(Palette.label2)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                PricingPriceBar(card: card)
                Text(card.legend)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let suggestion = card.suggestion {
                suggestionBox(suggestion)
            }
            HStack {
                Spacer()
                Button("Edit Prices…", action: onOpen)
                    .buttonStyle(.link)
                    .controlSize(.small)
                    .accessibilityLabel(Text("Edit every price of \(card.product.name)"))
                    .accessibilityIdentifier("pricing.card.open")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: shape)
        .overlay(
            shape.strokeBorder(card.suggestion == nil ? Palette.separator : Palette.suggestionBadge.opacity(0.6), lineWidth: card.suggestion == nil ? 0.5 : 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.card.\(card.product.productID)")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
    }

    private func suggestionBox(_ suggestion: PricingProductCard.Suggestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: "sparkle")
                    .imageScale(.small)
                    .foregroundStyle(Palette.machineTranslated)
                    .accessibilityHidden(true)
                Text("Suggested")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.machineTranslated)
                SuggestionSourceTag(source: .builtIn)
            }
            Text(suggestion.title)
                .font(.callout.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("pricing.card.suggestion")
            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.small) {
                Button(isExpanded ? "Hide Countries" : "Show Countries", action: onToggleCountries)
                    .accessibilityIdentifier("pricing.card.countriesToggle")
                Spacer(minLength: Spacing.small)
                Button("Dismiss", action: onDismiss)
                    .accessibilityIdentifier("pricing.card.dismiss")
                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("pricing.card.accept")
            }
            .controlSize(.small)
            if isExpanded {
                PricingCountriesTable(suggestion: suggestion)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, Spacing.small)
        .background(Palette.machineTranslatedTint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
