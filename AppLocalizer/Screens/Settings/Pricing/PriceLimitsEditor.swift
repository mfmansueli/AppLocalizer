//
//  PriceLimitsEditor.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Pricing → Floor · ceiling → Edit…: how far a suggested price
/// may go from the base price. The ceiling only matters when "Discount
/// only" is off.
struct PriceLimitsEditor: View {
    @Binding var strategy: PricingStrategy

    var body: some View {
        Form {
            Stepper(value: percent(\.floor), in: 0...100, step: 5) {
                LabeledContent("Floor", value: "\(Int(percent(\.floor).wrappedValue))%")
            }
            Stepper(value: percent(\.ceiling), in: 100...300, step: 10) {
                LabeledContent("Ceiling", value: "\(Int(percent(\.ceiling).wrappedValue))%")
            }
            .disabled(strategy.discountOnly)
            if strategy.discountOnly {
                Text("Turn off Discount only to allow prices above the base.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
        }
        .formStyle(.grouped)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func percent(_ keyPath: WritableKeyPath<PricingStrategy, Decimal>) -> Binding<Double> {
        Binding(
            get: { NSDecimalNumber(decimal: strategy[keyPath: keyPath] * 100).doubleValue },
            set: { value in strategy.customize { $0[keyPath: keyPath] = Decimal(Int(value.rounded())) / 100 } }
        )
    }
}
