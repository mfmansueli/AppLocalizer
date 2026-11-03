//
//  AutopilotAddScreensFooter.swift
//  AppLocalizer
//

import SwiftUI

/// Under the plan's iPhone and iPad screens: the form or the assistant's
/// suggestions when open, then "+ Add a Screen…", what to ask for, and
/// Suggest Screens, and where new screens go. At Apple's 10 both are off.
struct AutopilotAddScreensFooter: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let client: String

    /// What the plan scrolls to when it opens: the form, Claude Code
    /// reading, the suggestions.
    enum ScrollTarget: Hashable {
        case form
        case busy
        case suggestions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if studio.screenDraft != nil {
                AutopilotScreenForm(studio: studio, client: client)
                    .id(ScrollTarget.form)
            }
            if run.screenRequest != nil {
                busy
                    .id(ScrollTarget.busy)
            }
            if let suggestions = run.screenSuggestions {
                AutopilotScreenSuggestionsBox(studio: studio, suggestions: suggestions)
                    .id(ScrollTarget.suggestions)
            }
            HStack(spacing: Spacing.small) {
                Button {
                    studio.openScreenForm()
                } label: {
                    Label("Add a Screen…", systemImage: "plus")
                }
                .disabled(studio.plansMaximumScreens)
                .accessibilityIdentifier("autopilot.plan.addScreen")
                TextField(String(localized: "Ask for a screen, e.g. “one that shows the streak”"), text: $studio.screenAsk)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { if canSuggest { studio.suggestScreens() } }
                    .accessibilityLabel(Text("Ask \(client) for a screen"))
                    .accessibilityIdentifier("autopilot.plan.screenAsk")
                Button {
                    studio.suggestScreens()
                } label: {
                    Label("Suggest Screens", systemImage: "sparkles")
                }
                .disabled(!canSuggest)
                .accessibilityIdentifier("autopilot.plan.suggestScreens")
            }
            .controlSize(.small)
            Text(studio.addScreensNote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.plan.addScreensNote")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }

    private var canSuggest: Bool { run.screenRequest == nil && !studio.plansMaximumScreens }

    private var busy: some View {
        HStack(spacing: Spacing.small) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 1) {
                Text(studio.suggestBusyText(client: client))
                    .accessibilityIdentifier("autopilot.plan.suggestions.busyText")
                if studio.didCopySuggestPrompt {
                    Text("The prompt is copied: paste it into \(client).")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Cancel") { studio.cancelSuggestions() }
                .controlSize(.small)
                .accessibilityIdentifier("autopilot.plan.suggestions.cancel")
        }
        .padding(Spacing.small)
        .background(Palette.fill1.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.suggestions.busy")
    }
}
