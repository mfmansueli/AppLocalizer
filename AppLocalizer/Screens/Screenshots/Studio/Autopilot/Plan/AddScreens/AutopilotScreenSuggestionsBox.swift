//
//  AutopilotScreenSuggestionsBox.swift
//  AppLocalizer
//

import SwiftUI

/// The assistant's suggested screens, from Suggest Screens: each with why
/// and how, to add or dismiss; Done closes them. Nothing is added on its
/// own.
struct AutopilotScreenSuggestionsBox: View {
    @Bindable var studio: ScreenshotStudioModel
    let suggestions: AutopilotScreenSuggestions

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.small) {
                Label(suggestions.client, systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.machineTranslatedMark)
                Text(studio.suggestionsTitle(suggestions))
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("autopilot.plan.suggestions.title")
                Button("Done") { studio.closeSuggestions() }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("autopilot.plan.suggestions.done")
            }
            let shown = suggestions.shown
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, suggestion in
                if index > 0 { Divider() }
                AutopilotScreenSuggestionRow(studio: studio, suggestion: suggestion)
            }
            if shown.isEmpty {
                Text("No more suggestions. Ask for something specific below.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
        }
        .padding(Spacing.medium)
        .background(Palette.machineTranslatedTint.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.suggestions")
    }
}
