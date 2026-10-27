//
//  CompareSourcesView.swift
//  AppLocalizer
//

import SwiftUI

/// Today's price, the equalized one and each index's, side by side as bars.
/// “Use This” sets the territory by hand.
struct CompareSourcesView: View {
    let territoryID: String
    let comparisons: [SourceComparison]
    let currency: CurrencyFormat
    let canEdit: Bool
    let onUse: (Decimal) -> Void

    var body: some View {
        let maximum = comparisons.compactMap(\.price).max() ?? 1
        VStack(alignment: .leading, spacing: Spacing.small) {
            ForEach(comparisons) { comparison in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(comparison.title).font(.callout)
                        Spacer()
                        Text(comparison.price.map { currency.format($0) } ?? String(localized: "No data"))
                            .font(.callout.weight(.semibold).monospacedDigit())
                    }
                    HStack(spacing: Spacing.small) {
                        MeterBar(
                            fraction: comparison.price.map { maximum > 0 ? ($0 / maximum).doubleValue : 0 } ?? 0,
                            tint: tint(for: comparison.kind),
                            height: 6
                        )
                        .accessibilityHidden(true)
                        if comparison.canUse, canEdit, let price = comparison.price {
                            Button("Use This") { onUse(price) }
                                .controlSize(.small)
                                .buttonBorderShape(.capsule)
                                .accessibilityLabel(String(localized: "Use \(comparison.title), \(currency.format(price))"))
                        }
                    }
                }
                .accessibilityElement(children: .contain)
            }
            Text("“Use this” sets the territory by hand; it then shows as Edited manually.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("pricing.compareSources")
    }

    private func tint(for kind: SourceComparison.Kind) -> Color {
        switch kind {
        case .current: Palette.label3
        case .equalized: Palette.label2
        case .index: Palette.accent
        }
    }
}
