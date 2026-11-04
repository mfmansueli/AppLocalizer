//
//  AutopilotAddScreensFooter.swift
//  AppLocalizer
//

import SwiftUI

/// Under the plan's iPhone and iPad screens, and under Apple Watch's own:
/// the form or the assistant's suggestions when open for that device, then
/// "+ Add a Screen…", what to ask for, and Suggest Screens, and where new
/// screens go. At Apple's 10 both are off.
struct AutopilotAddScreensFooter: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let client: String
    /// iPhone for the set's screens, or Apple Watch.
    var display: ScreenshotDisplayType = .iPhone

    /// What the plan scrolls to when it opens: the form, Claude Code
    /// reading, the suggestions.
    enum ScrollTarget: Hashable {
        case form
        case busy
        case suggestions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if studio.screenDraft?.displayType == display {
                AutopilotScreenForm(studio: studio, client: client)
                    .id(ScrollTarget.form)
            }
            if run.screenRequest?.device == display {
                busy
                    .id(ScrollTarget.busy)
            }
            if let suggestions = run.screenSuggestions, suggestions.device == display {
                AutopilotScreenSuggestionsBox(studio: studio, suggestions: suggestions)
                    .id(ScrollTarget.suggestions)
            }
            HStack(spacing: Spacing.small) {
                Button {
                    studio.openScreenForm(on: display)
                } label: {
                    Label("Add a Screen…", systemImage: "plus")
                }
                .disabled(isFull)
                .accessibilityIdentifier(identifier("autopilot.plan.addScreen"))
                TextField(askPlaceholder, text: ask)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { if canSuggest { studio.suggestScreens(on: display) } }
                    .accessibilityLabel(Text(display == .watch ? "Ask \(client) for an Apple Watch screen" : "Ask \(client) for a screen"))
                    .accessibilityIdentifier(identifier("autopilot.plan.screenAsk"))
                Button {
                    studio.suggestScreens(on: display)
                } label: {
                    Label("Suggest Screens", systemImage: "sparkles")
                }
                .disabled(!canSuggest)
                .accessibilityIdentifier(identifier("autopilot.plan.suggestScreens"))
            }
            .controlSize(.small)
            Text(studio.addScreensNote(on: display))
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier("autopilot.plan.addScreensNote"))
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }

    private var isFull: Bool { studio.plansMaximumScreens(on: display) }

    /// One request at a time, whichever device it's for.
    private var canSuggest: Bool { run.screenRequest == nil && !isFull }

    private var ask: Binding<String> {
        Binding { studio.screenAsk(on: display) } set: { studio.setScreenAsk($0, on: display) }
    }

    private var askPlaceholder: String {
        display == .watch
            ? String(localized: "Ask for a watch screen, e.g. “one that shows today’s mood”")
            : String(localized: "Ask for a screen, e.g. “one that shows the streak”")
    }

    /// The set's buttons keep their identifiers; Apple Watch's end in
    /// `.watch`.
    private func identifier(_ base: String) -> String {
        display.hasOwnScreens ? "\(base).\(display.mcpValue)" : base
    }

    private var busy: some View {
        HStack(spacing: Spacing.small) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 1) {
                Text(studio.suggestBusyText(client: client, on: display))
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
