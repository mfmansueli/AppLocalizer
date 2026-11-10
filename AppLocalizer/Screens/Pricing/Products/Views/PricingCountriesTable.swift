//
//  PricingCountriesTable.swift
//  AppLocalizer
//

import SwiftUI

/// Show Countries: the suggestion's countries with today's price, the
/// suggested one and the change, then how many more.
struct PricingCountriesTable: View {
    let suggestion: PricingProductCard.Suggestion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Spacing.medium, verticalSpacing: 5) {
                GridRow {
                    Text("Country")
                    Text("Now").gridColumnAlignment(.trailing)
                    Text("Suggested").gridColumnAlignment(.trailing)
                    Text(verbatim: "%").gridColumnAlignment(.trailing)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
                Divider()
                ForEach(suggestion.countries) { country in
                    GridRow {
                        Text(country.name)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(country.now)
                            .foregroundStyle(Palette.label2)
                        Text(country.suggested)
                            .foregroundStyle(Palette.machineTranslated)
                        Text(country.change)
                            .foregroundStyle(Palette.label2)
                    }
                    .font(.caption.monospacedDigit())
                    .lineLimit(1)
                    .accessibilityElement(children: .combine)
                }
            }
            if suggestion.moreCount > 0 {
                Text(suggestion.moreCount == 1
                    ? String(localized: "and 1 more country or region")
                    : String(localized: "and \(suggestion.moreCount) more countries and regions"))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
        }
        .padding(Spacing.medium)
        .background(Palette.content, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.card.countries")
    }
}
