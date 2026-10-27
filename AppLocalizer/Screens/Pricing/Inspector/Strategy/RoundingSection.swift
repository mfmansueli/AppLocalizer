//
//  RoundingSection.swift
//  AppLocalizer
//

import SwiftUI

/// Which price endings proposals snap to, and whether prices may go up.
struct RoundingSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        InspectorSection(.rounding, in: model) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Picker(String(localized: "Rounding"), selection: viewModel.strategyBinding(\.rounding)) {
                    ForEach(PriceRounding.allCases, id: \.self) { rounding in
                        Text(rounding.title).tag(rounding)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("pricing.rounding")
                Text("""
                Always the nearest of Apple’s price points, about 800 per currency. Auto uses each currency’s usual \
                ending (,90 in Brazil, round yen and won).
                """)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                Toggle(isOn: viewModel.strategyBinding(\.neverRaise)) {
                    Text("Never raise existing prices").font(.callout)
                }
                .toggleStyle(.switch)
                Text("Keeps today’s price wherever the strategy would go higher.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
        }
    }
}
