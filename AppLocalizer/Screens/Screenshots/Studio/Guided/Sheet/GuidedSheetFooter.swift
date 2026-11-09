//
//  GuidedSheetFooter.swift
//  AppLocalizer
//

import SwiftUI

/// The guided sheet's bottom line: what you'll get, how long it takes or
/// what's next, and the step's buttons: Next and Back while it's set up,
/// Start Autopilot, Cancel Run… while it runs, Use These, and Push to App
/// Store….
struct GuidedSheetFooter: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let step: GuidedStep
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?
    @Environment(PushController.self) private var push: PushController?

    var body: some View {
        // Looked at again each minute: a pasted run goes quiet with time.
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            HStack(spacing: Spacing.small) {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("autopilot.guided.footer.text")
                if step == .making || step == .choose, studio.stall != nil {
                    Button(launcher?.canStart == true ? String(localized: "Continue") : String(localized: "Copy the Prompt to Continue")) {
                        studio.continueRun()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("autopilot.guided.continue")
                }
                buttons
            }
            .buttonBorderShape(.capsule)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
        .confirmationDialog(Text("Push to App Store Connect?"), isPresented: $studio.guided.isConfirmingPush) {
            Button("Push") {
                guard let push else { return }
                Task { await studio.pushGuided(with: push) }
            }
            .accessibilityIdentifier("autopilot.guided.push.confirm")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pushMessage)
        }
    }

    private var plan: AutopilotPlan { run.plan }

    private var text: String {
        if step == .making || step == .choose, let stall = studio.stall { return stall.footer(of: run) }
        switch step {
        case .make:
            return GuidedMakeSummary.sentence(plan)
        case .look:
            return String(localized: "Everything here can be changed later with Ask for Changes.")
        case .plan:
            if let simulators = launcher?.simulators {
                let check = GuidedMacCheck(run: run, state: simulators.state)
                if check.helperCantCheck {
                    return String(localized: "Save the helper again so AppLocalizer can check this Mac before Start.")
                }
                if !check.missing.isEmpty {
                    let names = check.missing.map(\.title).formatted(.list(type: .and))
                    return String(localized: "Start waits for \(names): make or install its simulator in This Mac, or turn it off.")
                }
            }
            let minutes = GuidedMakeSummary.minutes(plan, design: studio.plannedDesignKind, kept: run.capturesKeptAtStart)
            return String(localized: "About \(minutes) min. Autopilot stops only where it says You.")
        case .making:
            if run.stage == .pick { return studio.pickFooterText(run) }
            if run.waitsOnlyOnProblems { return String(localized: "Everything else is in. The run goes on once you decide what’s left above.") }
            if !run.openProblems.isEmpty { return String(localized: "A problem needs you before this part goes on; the rest keeps going.") }
            return String(localized: "You can close this window; Autopilot keeps going.")
        case .choose:
            return chooseHint
        case .review:
            let parts = studio.guidedParts.count
            let approved = studio.guidedApprovedCount
            if run.stage == .watchPreview, approved == parts {
                return String(localized: "Making the last changes before the push.")
            }
            return String(localized: "\(approved) of \(parts) approved. Nothing is sent until you push.")
        case .done:
            return ""
        }
    }

    /// "Next, AppLocalizer localizes your choice into 18 languages. About
    /// 5 min.", or what's still to choose.
    private var chooseHint: String {
        let needsLook = run.choosesDirection && run.directionToUse == nil
        let needsHeader = run.usesConcepts && run.chosenConcept == nil
        switch (needsLook, needsHeader) {
        case (true, true):
            return String(localized: "Choose a screenshot look and a header.")
        case (true, false):
            return plan.makesScreenshots ? String(localized: "Choose a screenshot look.") : String(localized: "Choose the App Preview’s look.")
        case (false, true):
            return String(localized: "Choose a header.")
        case (false, false):
            let count = plan.localeCodes.count
            let minutes = GuidedMakeSummary.localizeMinutes(plan)
            return count == 1
                ? String(localized: "Next, AppLocalizer checks your choice in \(GuidedMakeSummary.primaryName(plan)). About \(minutes) min.")
                : String(localized: "Next, AppLocalizer localizes your choice into \(count) languages. About \(minutes) min.")
        }
    }

    private var canUseChoices: Bool {
        run.usesConcepts ? run.canUseChoices : run.directionToUse != nil
    }

    private var pushMessage: String {
        let what = GuidedMakeSummary.pushed(plan) ?? String(localized: "Everything")
        return String(localized: "\(what) go to App Store Connect. The live page changes when Apple finishes processing, usually within minutes.")
    }

    @ViewBuilder
    private var buttons: some View {
        switch step {
        case .make:
            Button("Next: The Look") { studio.guided.setupStep = .look }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(plan.makesNothing)
                .accessibilityIdentifier("autopilot.guided.next")
        case .look:
            Button("Back") { studio.guided.setupStep = .make }
                .accessibilityIdentifier("autopilot.guided.back")
            Button("Next: Check the Plan") { studio.guided.setupStep = .plan }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("autopilot.guided.next")
        case .plan:
            Button("Back") { studio.guided.setupStep = .look }
                .accessibilityIdentifier("autopilot.guided.back")
            let macWaits = launcher.map { GuidedMacCheck(run: run, state: $0.simulators.state).blocksStart } == true
            Button("Start Autopilot") { studio.startGuided() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(plan.makesNothing || macWaits)
                .help(macWaits ? Text(GuidedMacCheck.blockedHelp) : Text("Starts Autopilot; it stops only where the plan says You."))
                .accessibilityIdentifier("autopilot.guided.start")
        case .making:
            makingButtons
        case .choose:
            AutopilotCancelRunButton(studio: studio, run: run)
            Button("Use These") { useChoices() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canUseChoices)
                .accessibilityIdentifier("autopilot.guided.useChoices")
        case .review:
            if run.stage == .watchPreview { AutopilotCancelRunButton(studio: studio, run: run) }
            Button("Push to App Store…") { studio.guided.isConfirmingPush = true }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!studio.canPushGuided || push == nil)
                .accessibilityIdentifier("autopilot.guided.push")
        case .done:
            EmptyView()
        }
    }

    @ViewBuilder
    private var makingButtons: some View {
        switch run.stage {
        case .waiting:
            Button("Cancel Run") { studio.stop() }
                .accessibilityIdentifier("autopilot.guided.cancelRun")
        case .capture:
            AutopilotCancelRunButton(studio: studio, run: run, identifier: "autopilot.guided.cancelRun")
        case .pick:
            AutopilotCancelRunButton(studio: studio, run: run)
            Button("Use These Picks") { studio.usePicks() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!studio.canUsePicks(run))
                .accessibilityIdentifier("autopilot.guided.usePicks")
        default:
            AutopilotCancelRunButton(studio: studio, run: run)
        }
    }

    /// Use These: the look and header chosen go on to Localize.
    private func useChoices() {
        if run.usesConcepts {
            studio.useChoices()
        } else if let direction = run.directionToUse {
            studio.useDirection(direction)
        }
    }
}
