//
//  NewLanguagesBanner.swift
//  AppLocalizer
//

import SwiftUI

/// On an App Store language's tab while the project has languages the App
/// Store page doesn't: "Lumen Journal’s 1.4 build supports 3 more languages
/// than its App Store page: Polish, Turkish, Hebrew. People who use them see
/// the English page.", with Review… (the languages sheet) and Add All 3.
/// Suggestion purple, since it's AppLocalizer's suggestion.
struct NewLanguagesBanner: View {
    let text: String
    let addTitle: String
    let onReview: () -> Void
    let onAddAll: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "globe")
                .foregroundStyle(Palette.machineTranslated)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("storePage.newLanguages.text")
            Button("Review…", action: onReview)
                .accessibilityIdentifier("storePage.newLanguages.review")
            Button(addTitle, action: onAddAll)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("storePage.newLanguages.addAll")
        }
        .controlSize(.small)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 2)
        .background(Palette.machineTranslatedTint, in: shape)
        .overlay(shape.strokeBorder(Palette.machineTranslatedMark.opacity(contrast == .increased ? 0.8 : 0.35), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.newLanguages")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
    }
}

#Preview {
    NewLanguagesBanner(
        text: "Lumen Journal’s 1.4 build supports 3 more languages than its App Store page: Polish, Turkish, Hebrew. "
            + "People who use them see the English page.",
        addTitle: "Add All 3",
        onReview: {},
        onAddAll: {}
    )
    .padding()
    .frame(width: 720)
}
