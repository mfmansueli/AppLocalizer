//
//  AutopilotSheetFooter.swift
//  AppLocalizer
//

import SwiftUI

/// The sheet's bottom line: what's happening or what to do, and the
/// stage's buttons. A run nobody works on any more says so, with Continue.
struct AutopilotSheetFooter: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let onReview: () -> Void
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        // Looked at again each minute: a pasted run goes quiet with time.
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            HStack(spacing: Spacing.small) {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.footer.text")
                Spacer()
                if studio.stall != nil {
                    Button(launcher?.canStart == true ? String(localized: "Continue") : String(localized: "Copy the Prompt to Continue")) {
                        studio.continueRun()
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("autopilot.continue")
                }
                buttons
            }
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
    }

    private var client: String { run.client ?? String(localized: "The assistant") }

    /// The footer follows the run, not the stage looked at.
    private var text: String {
        if let stall = studio.stall { return stall.footer(of: run) }
        return switch run.stage {
        case .plan where run.plan.makesNothing:
            String(localized: "Turn on at least one row in What this run makes.")
        case .plan:
            if let missing = launcher?.simulators.missing(in: run.plan.runDisplays), !missing.isEmpty {
                String(localized: "This Mac can’t capture \(missing.map(\.title).formatted(.list(type: .and))) yet: install the simulator, or turn it off.")
            } else {
                AutopilotEstimate.summary(
                    for: run.plan, design: studio.designProject?.kind ?? .none, kept: run.plan.reusesCaptures || run.startedAt != nil ? run.keptCaptureCount : 0
                )
            }
        case .waiting where studio.launchedRun != nil:
            String(localized: "Claude Code asks AppLocalizer what to do from there; the stages move on as captures arrive.")
        case .waiting:
            String(localized: "Paste the prompt into \(run.clientName(assistant: nil)). It asks AppLocalizer what to do from there.")
        case .capture:
            if run.openProblems.isEmpty {
                String(localized: "You can hide this; the strip above the preview shows the progress.")
            } else {
                String(localized: "Resolve the problem to continue to the next stage.")
            }
        case .pick: studio.pickFooterText(run)
        case .design: String(localized: "Directions arrive one by one; then you choose one.")
        case .choose where run.usesConcepts: chooseText
        case .choose where !run.plan.makesScreenshots:
            String(localized: "The direction you use styles \(run.plan.extrasTitle ?? String(localized: "the extras")); your template stays as it is.")
        case .choose: String(localized: "The direction you use becomes template v\((studio.screenshots.document?.history?.currentNumber ?? 0) + 1).")
        case .localize where !run.plan.makesScreenshots:
            String(localized: "Rendering on this Mac. \(client) only steps in when a headline is missing or doesn’t fit.")
        case .localize:
            if AutopilotCaptionWork(run.overflows).isEmpty {
                String(localized: "Rendering on this Mac. \(client) only steps in when a caption is missing or doesn’t fit.")
            } else {
                String(localized: "\(client) writes the captions; AppLocalizer checks each language again when they arrive.")
            }
        case .watchPreview: watchText
        case .ready: String(localized: "Nothing is uploaded until you push.")
        }
    }

    /// "Choose a screenshot direction and a header.", "Your direction
    /// becomes template v5; the header goes into the new set."
    private var chooseText: String {
        let needsDirection = run.hasDirections && run.directionToUse == nil
        let needsHeader = run.chosenConcept == nil
        let direction = run.plan.makesScreenshots ? String(localized: "a screenshot direction") : String(localized: "the App Preview’s look")
        switch (needsDirection, needsHeader) {
        case (true, true): return String(localized: "Choose \(direction) and a header.")
        case (true, false): return String(localized: "Choose \(direction).")
        case (false, true): return String(localized: "Choose a header.")
        case (false, false):
            guard run.plan.makesScreenshots else { return String(localized: "The header goes into the new set.") }
            let version = (studio.screenshots.document?.history?.currentNumber ?? 0) + 1
            return String(localized: "Your direction becomes template v\(version); the header goes into the new set.")
        }
    }

    /// "Approving keeps this App Preview for English (U.S.); other
    /// languages show it."
    private var watchText: String {
        if let remake = run.previewReview?.remake { return remake.title + "…" }
        if run.previewReview?.request != nil {
            return String(localized: "\(run.designKind.title) is making your changes; you approve the new version.")
        }
        let loop = run.watchesHeaderLoop(design: run.designKind)
        if loop, run.loopReview?.request != nil {
            return String(localized: "\(run.designKind.title) is revising the loop; you approve the new version.")
        }
        if loop, run.loopReview?.isRemaking == true {
            return String(localized: "AppLocalizer is making the header loop again.")
        }
        guard run.watchesAppPreview else {
            return String(localized: "Approving keeps this loop for the header and search in every language.")
        }
        if run.plan.alsoMakes.previewLanguages == .all {
            return loop
                ? String(localized: "Approving applies this cut to every language’s App Preview, and keeps the header loop.")
                : String(localized: "Approving applies this cut to every language’s App Preview.")
        }
        let primary = StoreLocaleCatalog.locale(code: run.plan.primaryLocale)?.name ?? run.plan.primaryLocale
        return loop
            ? String(localized: "Approving keeps this App Preview for \(primary); other languages show it. The header loop is kept too.")
            : String(localized: "Approving keeps this App Preview for \(primary); other languages show it.")
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
                .disabled(run.plan.makesNothing)
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
            AutopilotCancelRunButton(studio: studio, run: run)
            Button("Use These Picks") { studio.usePicks() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.defaultAction)
                .disabled(!studio.canUsePicks(run))
                .accessibilityIdentifier("autopilot.usePicks")
        case .choose where run.usesConcepts:
            AutopilotCancelRunButton(studio: studio, run: run)
            Button(run.hasDirections ? String(localized: "Use These") : String(localized: "Use This Header")) { studio.useChoices() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.defaultAction)
                .disabled(!run.canUseChoices)
                .accessibilityIdentifier("autopilot.choose.useChoices")
        case .design, .choose, .localize:
            AutopilotCancelRunButton(studio: studio, run: run)
        case .watchPreview:
            AutopilotCancelRunButton(studio: studio, run: run)
            Button(run.approveTitle) { studio.approvePreview() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .keyboardShortcut(.defaultAction)
                .disabled(run.previewReview?.isBusy == true || AutopilotCenter.loopIsBusy(run))
                .accessibilityIdentifier("autopilot.watch.approve")
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
