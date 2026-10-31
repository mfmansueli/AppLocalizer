//
//  AutopilotSheetFooter.swift
//  AppLocalizer
//

import SwiftUI

/// The sheet's bottom line: what's happening or what to do, and the
/// stage's buttons.
struct AutopilotSheetFooter: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let onReview: () -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text(text)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("autopilot.footer.text")
            Spacer()
            buttons
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    private var client: String { run.client ?? String(localized: "The assistant") }

    /// The footer follows the run, not the stage looked at.
    private var text: String {
        switch run.stage {
        case .plan:
            AutopilotEstimate.summary(for: run.plan, design: studio.designProject?.kind ?? .none, kept: run.keptCaptureCount)
        case .waiting:
            String(localized: "Paste the prompt into \(run.clientName(assistant: nil)). It asks AppLocalizer what to do from there.")
        case .capture:
            if run.openProblems.isEmpty {
                String(localized: "You can hide this; the strip above the preview shows the progress.")
            } else {
                String(localized: "Resolve the problem to continue to the next stage.")
            }
        case .pick: String(localized: "\(client)’s picks are selected.")
        case .design: String(localized: "Directions arrive one by one; then you choose one.")
        case .choose: String(localized: "The direction you use becomes template v\((studio.screenshots.document?.history?.currentNumber ?? 0) + 1).")
        case .localize: String(localized: "Rendering on this Mac. \(client) only steps in when a caption doesn’t fit.")
        case .ready: String(localized: "Nothing is uploaded until you push.")
        }
    }

    @ViewBuilder
    private var buttons: some View {
        switch run.stage {
        case .plan:
            Button("Cancel") { studio.cancelPlan() }
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("autopilot.cancel")
            Button("Start Autopilot") { studio.start() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("autopilot.start")
        case .waiting:
            Button("Cancel Run") { studio.stop() }
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("autopilot.cancelRun")
        case .capture:
            Button("Stop") { studio.stop() }
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("autopilot.stop")
        case .pick:
            Button("Use These Picks") { studio.usePicks() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("autopilot.usePicks")
        case .design, .choose, .localize:
            EmptyView()
        case .ready:
            Button("Review & Push…", action: onReview)
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("autopilot.reviewPush")
            Button("See the Preview") { studio.seePreview() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("autopilot.seePreview")
        }
    }
}
