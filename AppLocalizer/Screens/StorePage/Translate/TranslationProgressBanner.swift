//
//  TranslationProgressBanner.swift
//  AppLocalizer
//

import SwiftUI

/// While a batch runs: "Translating with Apple Translation · 17 of 41 ·
/// Korean · Description", a progress bar, and Cancel, which keeps what's
/// finished as suggestions.
struct TranslationProgressBanner: View {
    let translation: TranslateMissingViewModel

    var body: some View {
        HStack(spacing: Spacing.medium) {
            ProgressView()
                .controlSize(.small)
            VStack(alignment: .leading, spacing: 5) {
                Text("\(Text("Translating with \(translation.runProvider.shortTitle)").fontWeight(.semibold)) · \(translation.job?.progressLine ?? "")")
                    .font(.callout)
                    .monospacedDigit()
                    .lineLimit(1)
                    .accessibilityIdentifier("storePage.translationProgress")
                ProgressView(value: translation.job?.fractionCompleted ?? 0)
                    .progressViewStyle(.linear)
                    .tint(Palette.accent)
                    .accessibilityHidden(true)
            }
            Button("Cancel") {
                translation.cancel()
            }
            .controlSize(.small)
            .accessibilityIdentifier("storePage.cancelTranslation")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .padding(.horizontal, Spacing.medium)
        .padding(.bottom, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.translationBanner")
    }
}
