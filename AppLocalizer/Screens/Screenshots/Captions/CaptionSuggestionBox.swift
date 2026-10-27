//
//  CaptionSuggestionBox.swift
//  AppLocalizer
//

import SwiftUI

/// A shorter version with its own fit meter, Use This and Keep Mine.
struct CaptionSuggestionBox: View {
    let suggestion: CaptionSuggestion
    let isRightToLeft: Bool
    let onUse: () -> Void
    let onKeep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Suggestion · \(suggestion.providerTitle)")
                .textCase(.uppercase)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Palette.label2)
            Text(suggestion.headline)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
                .textSelection(.enabled)
                .accessibilityIdentifier("screenshots.captions.editor.suggestion")
            FitMeter(value: FitMeterValue(fit: suggestion.fit))
                .padding(.vertical, 2)
            Text(suggestion.fit.label)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(suggestion.fit.tone == .overflows ? Palette.danger : Palette.label2)
            HStack(spacing: Spacing.xSmall) {
                Button("Use This", action: onUse)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("screenshots.captions.editor.useSuggestion")
                Button("Keep Mine", action: onKeep)
                    .accessibilityIdentifier("screenshots.captions.editor.keepMine")
            }
            .controlSize(.small)
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
    }
}
