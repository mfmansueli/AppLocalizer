//
//  NewLanguageCard.swift
//  AppLocalizer
//

import SwiftUI

/// On the tab of a language the project has and the App Store doesn't,
/// before it's added: a built-in suggestion to create its page. "Polish
/// isn’t on the App Store yet", why, who drafted it, Not Now and Create
/// Page. The fields below it are empty, with their suggestions.
struct NewLanguageCard: View {
    let title: String
    let text: String
    let onNotNow: () -> Void
    let onCreate: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "globe")
                .foregroundStyle(Palette.machineTranslated)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.xSmall) {
                    Pill(text: String(localized: "Suggested"), style: .machineTranslated)
                    SuggestionSourceTag(source: .builtIn)
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .accessibilityIdentifier("storePage.newLanguage.title")
                }
                Text(text)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("storePage.newLanguage.text")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Not Now", action: onNotNow)
                .accessibilityIdentifier("storePage.newLanguage.notNow")
            Button("Create Page", action: onCreate)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("storePage.newLanguage.create")
        }
        .controlSize(.small)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, 14)
        .padding(.vertical, Spacing.medium)
        .background(Palette.machineTranslatedTint, in: shape)
        .overlay(shape.strokeBorder(Palette.machineTranslatedMark.opacity(contrast == .increased ? 0.8 : 0.35), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.newLanguage")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
    }
}

#Preview {
    NewLanguageCard(
        title: "Polish isn’t on the App Store yet",
        text: "Lumen Journal’s 1.4 build is translated into Polish (Localizable.xcstrings: 412 of 418 strings (98%)). "
            + "People who use Polish see the English page today. Claude Code drafted the page below.",
        onNotNow: {},
        onCreate: {}
    )
    .padding()
    .frame(width: 720)
}
