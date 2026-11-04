//
//  AutopilotScreenSuggestionRow.swift
//  AppLocalizer
//

import SwiftUI

/// One suggested screen: its name, why, how to reach it and its caption,
/// with Dismiss and Add to Plan, or "Added" once it's in the plan.
struct AutopilotScreenSuggestionRow: View {
    @Bindable var studio: ScreenshotStudioModel
    let suggestion: AutopilotScreenSuggestion
    /// The device it's added to: iPhone for the set's screens, or Apple
    /// Watch.
    var display: ScreenshotDisplayType = .iPhone

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.name).fontWeight(.semibold)
                Text(suggestion.reason)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if let evidence = suggestion.evidence {
                    Text(evidence)
                        .font(.caption)
                        .foregroundStyle(Palette.label3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(suggestion.steps)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if !suggestion.caption.isEmpty {
                    Text("Caption: “\(suggestion.caption)”").font(.caption)
                }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            switch suggestion.status {
            case .open:
                HStack(spacing: Spacing.xSmall) {
                    Button("Dismiss") { studio.dismissSuggestedScreen(suggestion.id) }
                        .accessibilityIdentifier("autopilot.plan.suggestion.\(suggestion.id).dismiss")
                    Button("Add to Plan") { studio.addSuggestedScreen(suggestion.id) }
                        .buttonStyle(.borderedProminent)
                        .disabled(studio.plansMaximumScreens(on: display))
                        .accessibilityIdentifier("autopilot.plan.suggestion.\(suggestion.id).add")
                }
                .controlSize(.small)
            case .added:
                Label("Added", systemImage: "checkmark")
                    .font(.callout)
                    .foregroundStyle(Palette.positive)
                    .accessibilityIdentifier("autopilot.plan.suggestion.\(suggestion.id).added")
            case .dismissed:
                EmptyView()
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.suggestion.\(suggestion.id)")
    }
}
