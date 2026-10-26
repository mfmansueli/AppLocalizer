//
//  MethodSection.swift
//  AppLocalizer
//

import SwiftUI

/// How proposals are worked out: Recommended, Apple equalization, a price
/// index or custom regional tiers; and the base territory everything
/// derives from.
struct MethodSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let strategy = viewModel.strategy
        InspectorSection(.method, in: strategy) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(PricingMethod.allCases, id: \.self) { method in
                    Button {
                        viewModel.editStrategy { $0.method = method }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                            Image(systemName: strategy.strategy.method == method ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(strategy.strategy.method == method ? Palette.accent : Palette.label3)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(method.title).font(.body.weight(.medium))
                                Text(method.summary)
                                    .font(.caption)
                                    .foregroundStyle(Palette.label2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(strategy.strategy.method == method ? [.isSelected] : [])
                    .accessibilityIdentifier("pricing.method.\(method.rawValue)")
                }
                HStack {
                    Text("Base territory and price")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                    Spacer(minLength: Spacing.small)
                    Text(baseText)
                        .font(.callout)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 2)
                        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field))
                }
                .padding(.top, Spacing.xxSmall)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var baseText: String {
        let name = viewModel.strategy.baseTerritory?.name ?? String(localized: "United States")
        guard let price = viewModel.selectedProduct?.basePriceText else { return name }
        return "\(name) · \(price)"
    }
}
