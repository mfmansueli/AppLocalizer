//
//  FormulaSection.swift
//  AppLocalizer
//

import SwiftUI

/// The pricing formula in four lines, with the strategy's own numbers.
struct FormulaSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        let strategy = model.strategy
        InspectorSection(.formula, in: model) {
            VStack(alignment: .leading, spacing: 2) {
                Text("factor = \(strategy.indexSource.shortName) level, else the fallback chain")
                Text("target = equalized × (1 − \(strategy.intensity.fixed(2)) + \(strategy.intensity.fixed(2)) × factor)")
                Text(limitsLine(strategy))
                Text("price = nearest price point, \(strategy.rounding.title) endings")
            }
            .font(.caption.monospaced())
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field))
        }
    }

    private func limitsLine(_ strategy: PricingStrategy) -> String {
        let floor = strategy.floor.percentText
        guard !strategy.discountOnly else { return String(localized: "limits: ≥ \(floor)% of base, ≤ equalized") }
        return String(localized: "limits: ≥ \(floor)% of base, ≤ \(strategy.ceiling.percentText)% of equalized")
    }
}
