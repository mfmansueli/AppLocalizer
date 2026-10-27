//
//  RegionalTiersSection.swift
//  AppLocalizer
//

import SwiftUI

/// One multiplier per region, for the Custom regional tiers method.
struct RegionalTiersSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        InspectorSection(.regionalTiers, in: model) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                ForEach(TerritoryRegion.allCases, id: \.self) { region in
                    let multiplier = model.strategy.regionMultiplier(for: region)
                    Stepper(value: binding(for: region), in: 0.1...1.5, step: 0.05) {
                        HStack {
                            Text(region.title).font(.callout)
                            Spacer()
                            Text(verbatim: "× " + multiplier.fixed(2))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(Palette.label2)
                        }
                    }
                    .accessibilityValue(multiplier.fixed(2))
                }
                Text("Each region’s equalized prices are multiplied by its factor, then snapped to Apple’s price points.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func binding(for region: TerritoryRegion) -> Binding<Double> {
        Binding(
            get: { viewModel.strategy.strategy.regionMultiplier(for: region).doubleValue },
            set: { value in
                viewModel.editStrategy { $0.regionMultipliers[region] = Decimal(exactly: (value * 100).rounded() / 100) }
            }
        )
    }
}
