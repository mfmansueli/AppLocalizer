//
//  CaptionTranslationBanner.swift
//  AppLocalizer
//

import SwiftUI

/// While a batch runs: "Translating with Apple Translation · 7 of 20 ·
/// Polish · slot 3", a progress bar, and Cancel, which keeps every caption
/// already written.
struct CaptionTranslationBanner: View {
    let translation: CaptionTranslationViewModel

    var body: some View {
        HStack(spacing: Spacing.medium) {
            ProgressView()
                .controlSize(.small)
            VStack(alignment: .leading, spacing: 5) {
                Text("\(Text("Translating with \(translation.runProvider.shortTitle)")) · \(translation.job?.progressLine ?? "")")
                    .font(.callout)
                    .monospacedDigit()
                    .lineLimit(1)
                    .accessibilityIdentifier("screenshots.captions.translationProgress")
                ProgressView(value: translation.job?.fractionCompleted ?? 0)
                    .progressViewStyle(.linear)
                    .tint(Palette.accent)
                    .accessibilityHidden(true)
            }
            Button("Cancel") {
                translation.cancel()
            }
            .controlSize(.small)
            .accessibilityIdentifier("screenshots.captions.cancelTranslation")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .padding(.horizontal, Spacing.medium)
        .padding(.bottom, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.captions.translationBanner")
    }
}
