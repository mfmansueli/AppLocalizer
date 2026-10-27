//
//  CaptionTranslationLocaleList.swift
//  AppLocalizer
//

import SwiftUI

/// "LOCALES IN SCOPE": a checkbox per locale with empty captions, and how
/// many each has.
struct CaptionTranslationLocaleList: View {
    let translation: CaptionTranslationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Locales in scope")
                .textCase(.uppercase)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.label2)
            let plan = translation.plan
            VStack(spacing: 0) {
                ForEach(plan.locales) { locale in
                    Toggle(isOn: Binding {
                        translation.isIncluded(locale)
                    } set: {
                        translation.setIncluded(locale, $0)
                    }) {
                        HStack {
                            Text(locale.name)
                                .font(.callout)
                            Spacer()
                            Text(captionCount(plan.itemCount(in: locale)))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(Palette.label2)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .padding(.horizontal, Spacing.medium)
                    .frame(minHeight: 30)
                    .accessibilityIdentifier("screenshots.captions.translate.locale.\(locale.code)")
                    if locale != plan.locales.last {
                        Divider()
                    }
                }
                if plan.isEmpty {
                    Text("Nothing to translate: every locale in scope has its captions.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.medium)
                }
            }
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        }
    }

    private func captionCount(_ count: Int) -> String {
        count == 1 ? String(localized: "1 caption") : String(localized: "\(count) captions")
    }
}
