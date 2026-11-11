//
//  PaywallPlanRow.swift
//  AppLocalizer
//

import SwiftUI

/// One plan in the paywall: its name, what it costs in the person's
/// currency and how often, and "Save 50%" on Yearly.
struct PaywallPlanRow: View {
    let offer: ProOffer
    let tag: String?
    let isSelected: Bool
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: Spacing.xSmall) {
                        Text(offer.plan.title).font(.headline)
                        if let tag {
                            Text(tag)
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundStyle(Palette.positive)
                                .padding(.horizontal, 6)
                                .frame(height: 17)
                                .background(Palette.positive.opacity(0.16), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                    }
                    Text(offer.subtitle)
                        .font(.footnote)
                        .foregroundStyle(Palette.label2)
                }
                Spacer(minLength: Spacing.small)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(offer.displayPrice)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                    Text(offer.period)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(isSelected ? Palette.accentTint : Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : Palette.separator, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("paywall.plan.\(offer.plan.rawValue)")
    }
}

#Preview {
    VStack {
        PaywallPlanRow(
            offer: ProOffer(plan: .yearly, displayPrice: "$59.99", price: 59.99, monthlyDisplayPrice: "$5.00", trialDays: 7),
            tag: "Save 50%", isSelected: true
        ) {}
        PaywallPlanRow(offer: ProOffer(plan: .monthly, displayPrice: "$9.99", price: 9.99), tag: nil, isSelected: false) {}
    }
    .padding()
    .frame(width: 480)
}
