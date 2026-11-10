//
//  CompactSuggestionRow.swift
//  AppLocalizer
//

import SwiftUI

/// The suggestion under a question that's answered from a list: one line
/// with the suggested answer, who suggested it, Dismiss and Accept, and why
/// under it. Long texts use `FieldSuggestionCard`.
struct CompactSuggestionRow: View {
    let suggested: String
    let suggestion: FieldSuggestion
    let onDismiss: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: "sparkle")
                    .imageScale(.small)
                    .foregroundStyle(Palette.machineTranslated)
                    .accessibilityHidden(true)
                Text("Suggested: \(suggested)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.machineTranslated)
                    .accessibilityIdentifier("suggestion.value")
                SuggestionSourceTag(source: suggestion.source)
                Spacer(minLength: Spacing.small)
                Button("Dismiss", action: onDismiss)
                    .accessibilityIdentifier("suggestion.dismiss")
                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("suggestion.accept")
            }
            .controlSize(.small)
            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("suggestion.reason")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Palette.machineTranslatedTint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("suggestion.card")
    }
}
