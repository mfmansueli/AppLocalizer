//
//  CaptionTranslationGlossarySummary.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Translation's tone and terms not to translate, read-only:
/// they're changed in Settings.
struct CaptionTranslationGlossarySummary: View {
    let glossary: TranslationGlossary

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                title("Tone")
                Text(glossary.tone.title)
                    .font(.callout)
                    .accessibilityIdentifier("screenshots.captions.translate.tone")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                title("Don’t translate")
                if glossary.terms.isEmpty {
                    Text("No terms")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                } else {
                    FlowLayout(spacing: Spacing.xxSmall) {
                        ForEach(glossary.terms, id: \.self) { term in
                            Text(term)
                                .font(.caption)
                                .padding(.horizontal, Spacing.small)
                                .frame(height: 20)
                                .background(Palette.fill2, in: Capsule())
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("screenshots.captions.translate.terms")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }

    private func title(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .textCase(.uppercase)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.label2)
    }
}
