//
//  TiersSection.swift
//  AppLocalizer
//

import SwiftUI

/// Buckets territories by factor, so similar markets get the same discount.
struct TiersSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        let strategy = model.strategy
        InspectorSection(
            .tiers,
            in: model,
            trailing: {
                Toggle(String(localized: "Tiers"), isOn: viewModel.strategyBinding(\.tiersEnabled))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                    .accessibilityIdentifier("pricing.tiers")
            },
            content: {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Bucket territories by factor so similar markets get the same discount.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                    if strategy.tiersEnabled {
                        let counts = model.tierCounts
                        ForEach(Array(counts.enumerated()), id: \.offset) { index, count in
                            HStack(spacing: Spacing.xSmall) {
                                Pill(text: "T\(index + 1)", style: .outline)
                                Text(strategy.tiers.rule(forTier: index)).font(.callout.monospacedDigit())
                                Spacer()
                                Text(verbatim: strategy.tiers.share(forTier: index).percentText + "%")
                                    .font(.callout.monospacedDigit())
                                Text("\(count) territories")
                                    .font(.caption)
                                    .foregroundStyle(Palette.label2)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        )
    }
}
