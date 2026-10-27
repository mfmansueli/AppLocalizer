//
//  TranslateProviderRow.swift
//  AppLocalizer
//

import SwiftUI

/// A radio row in the Translate sheet: the provider's name and what it
/// does differently. Screenshots' caption sheet passes its own copy.
struct TranslateProviderRow: View {
    let provider: TranslationProvider
    let isSelected: Bool
    /// Replaces the provider's title, e.g. "AI provider · Anthropic".
    var title: String?
    /// Replaces the Store Page's description of the provider.
    var detail: String?
    /// The identifiers' prefix: "storePage.translate" by default.
    var identifierPrefix = "storePage.translate"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Palette.accent : Palette.label3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? provider.title)
                        .font(.callout.weight(.semibold))
                    Text(detail ?? provider.detail)
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
        .accessibilityIdentifier("\(identifierPrefix).provider.\(provider.rawValue)")
    }
}
