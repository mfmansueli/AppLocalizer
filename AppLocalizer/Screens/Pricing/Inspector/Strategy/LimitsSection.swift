//
//  LimitsSection.swift
//  AppLocalizer
//

import SwiftUI

/// How far the index moves prices, and the limits on it: floor, ceiling,
/// minimum proceeds and discounts only.
struct LimitsSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        let strategy = model.strategy
        InspectorSection(.limits, in: model) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: 2) {
                    labeledValue(String(localized: "Intensity"), value: strategy.intensity.percentText + "%")
                    Slider(value: viewModel.fractionBinding(\.intensity), in: 0...1, step: 0.05)
                        .accessibilityLabel(String(localized: "Intensity"))
                        .accessibilityValue(strategy.intensity.percentText + "%")
                        .accessibilityIdentifier("pricing.intensity")
                    HStack {
                        Text("0% · equalized")
                        Spacer()
                        Text("100% · full index")
                    }
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    labeledValue(String(localized: "Floor"), value: floorText(strategy))
                    Slider(value: viewModel.fractionBinding(\.floor), in: 0...0.8, step: 0.05)
                        .accessibilityLabel(String(localized: "Floor"))
                        .accessibilityValue(floorText(strategy))
                        .accessibilityIdentifier("pricing.floor")
                }
                if strategy.discountOnly {
                    Text("Ceiling: not needed while “Discount only” is on.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        labeledValue(String(localized: "Ceiling"), value: strategy.ceiling.percentText + "%")
                        Slider(value: viewModel.fractionBinding(\.ceiling), in: 1...2, step: 0.05)
                            .accessibilityLabel(String(localized: "Ceiling"))
                            .accessibilityValue(strategy.ceiling.percentText + "%")
                    }
                }
                HStack(spacing: Spacing.xSmall) {
                    Text("Minimum proceeds per territory").font(.callout)
                    Spacer(minLength: Spacing.xSmall)
                    Text(verbatim: "$").foregroundStyle(Palette.label2)
                    TextField(String(localized: "Off"), value: minimumProceeds, format: .number.precision(.fractionLength(0...2)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel(String(localized: "Minimum proceeds per territory, in dollars"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Toggle(isOn: viewModel.strategyBinding(\.discountOnly)) {
                        Text("Discount only").font(.callout)
                    }
                    .toggleStyle(.switch)
                    .accessibilityIdentifier("pricing.discountOnly")
                    Text("Never above the equalized price, even where the factor is above 1 (Switzerland, Norway). Turn off to allow premiums.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func labeledValue(_ title: String, value: String) -> some View {
        HStack {
            Text(title).font(.callout)
            Spacer()
            Text(value).font(.callout.monospacedDigit()).foregroundStyle(Palette.label2)
        }
        .accessibilityHidden(true)
    }

    private func floorText(_ strategy: PricingStrategy) -> String {
        let percent = strategy.floor.percentText + "%"
        guard let base = viewModel.selectedProduct?.basePrice else { return percent }
        let amount = CurrencyFormat.usd.format(base * strategy.floor)
        return String(localized: "\(percent) · never below \(amount)")
    }

    private var minimumProceeds: Binding<Double?> {
        Binding(
            get: { viewModel.strategy.strategy.minimumProceeds?.doubleValue },
            set: { value in
                viewModel.editStrategy { strategy in
                    strategy.minimumProceeds = value.flatMap { $0 > 0 ? Decimal(exactly: $0) : nil }
                }
            }
        )
    }
}
