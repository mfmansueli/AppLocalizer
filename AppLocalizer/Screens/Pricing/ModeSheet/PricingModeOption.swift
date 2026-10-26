//
//  PricingModeOption.swift
//  AppLocalizer
//

import SwiftUI

/// One choice in the pricing mode sheet: a radio, the mode's name and what
/// it does, and its symbol. The chosen one gets an accent outline.
struct PricingModeOption: View {
    let mode: PricingMode
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                    .font(.body)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    HStack(spacing: Spacing.xSmall) {
                        Text(mode.title).font(.body.weight(.semibold))
                        if mode == .showSuggestions {
                            Pill(text: String(localized: "Recommended"))
                        }
                    }
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.medium)
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Palette.label2)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : border, lineWidth: isSelected ? 2 : 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("pricing.modeSheet.option.\(mode.rawValue)")
    }

    private var border: Color {
        contrast == .increased ? Palette.separator2 : Palette.separator
    }

    private var description: String {
        switch mode {
        case .keepPrices: String(localized: "Translate only. Prices stay as they are, and AppLocalizer never proposes a change.")
        case .showSuggestions: String(localized: "See a suggested price per territory with its reason. Nothing changes until you apply it.")
        case .applyRecommended: String(localized: "Fill every territory with its suggestion now. You review everything before it’s pushed.")
        }
    }

    private var symbol: String {
        switch mode {
        case .keepPrices: "globe"
        case .showSuggestions: "lightbulb"
        case .applyRecommended: "tag"
        }
    }
}
