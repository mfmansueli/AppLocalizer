//
//  PricePointStepper.swift
//  AppLocalizer
//

import SwiftUI

/// The Proposed cell: − value +, stepping over Apple's price points. There's
/// never a free-form price. The value opens the breakdown.
struct PricePointStepper: View {
    let territoryID: String
    let territoryName: String
    let value: String
    var isDisabled = false
    let onStep: (Int) -> Void
    let onOpenBreakdown: () -> Void

    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        HStack(spacing: Spacing.xxSmall) {
            Button {
                onStep(-1)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 12, height: 16)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "Lower price point"))
            .accessibilityIdentifier("pricing.stepper.down.\(territoryID)")

            Button(action: onOpenBreakdown) {
                Text(value)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.xSmall)
                    .padding(.vertical, 1)
                    .background(field, in: RoundedRectangle(cornerRadius: Radius.badge))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.badge).strokeBorder(Palette.separator2, lineWidth: 0.5)
                    }
            }
            .accessibilityLabel(String(localized: "Proposed price for \(territoryName)"))
            .accessibilityValue(value)
            .accessibilityHint(String(localized: "Shows the price breakdown"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: onStep(1)
                case .decrement: onStep(-1)
                @unknown default: break
                }
            }
            .accessibilityIdentifier("pricing.proposed.\(territoryID)")

            Button {
                onStep(1)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 12, height: 16)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "Higher price point"))
            .accessibilityIdentifier("pricing.stepper.up.\(territoryID)")
        }
        .buttonStyle(.plain)
        .font(.caption.weight(.bold))
        .disabled(isDisabled)
        .accessibilityElement(children: .contain)
    }

    private var field: Color {
        prominence == .increased ? Color.white.opacity(0.18) : Palette.content
    }
}

#Preview {
    PricePointStepper(territoryID: "BRA", territoryName: "Brazil", value: "R$ 109,90", onStep: { _ in }, onOpenBreakdown: {})
        .padding()
}
