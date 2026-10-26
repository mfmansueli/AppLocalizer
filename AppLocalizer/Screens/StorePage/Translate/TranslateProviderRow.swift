//
//  TranslateProviderRow.swift
//  AppLocalizer
//

import SwiftUI

/// A radio row in the Translate sheet: the provider's name and what it
/// does differently.
struct TranslateProviderRow: View {
    let provider: TranslationProvider
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.title)
                        .font(.callout.weight(.semibold))
                    Text(provider.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("storePage.translate.provider.\(provider.rawValue)")
    }
}
