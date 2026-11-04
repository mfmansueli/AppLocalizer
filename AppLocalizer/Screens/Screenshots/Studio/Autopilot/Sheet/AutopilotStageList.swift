//
//  AutopilotStageList.swift
//  AppLocalizer
//

import SwiftUI

/// The eight stages, who does each, and where the run is; then what's
/// connected. The stages scroll when the sheet is short, so a long name
/// never makes the sheet taller than its window.
struct AutopilotStageList: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let assistant: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    ForEach(AutopilotStage.steps, id: \.self) { step in
                        AutopilotStageRow(
                            step: step,
                            title: run.title(of: step, design: design.kind),
                            who: who(step),
                            note: step == run.stage.step ? note?.text : nil,
                            noteIsProblem: note?.isProblem ?? true,
                            state: state(of: step),
                            isSelected: studio.shownStep == step
                        ) {
                            studio.viewedStep = step == run.stage.step ? nil : step
                        }
                        .disabled(!studio.canView(step))
                    }
                }
                .padding(Spacing.medium)
            }
            .scrollBounceBehavior(.basedOnSize)
            Divider()
                .padding(.horizontal, Spacing.medium)
            AutopilotConnectionsList(run: run, assistant: assistant, designProject: studio.designProject)
                .padding(Spacing.medium)
        }
        .background(Palette.window)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.stages")
    }

    private var client: String { run.clientName(assistant: assistant) }

    /// The run's row: the problems that need the person, or that nobody
    /// is working on it any more: red when it stopped or went quiet, plain
    /// when it's paused or Claude Code's turn (`AutopilotStall.stageNote`).
    private var note: (text: String, isProblem: Bool)? {
        if run.stage.step == .capture, !run.openProblems.isEmpty {
            let count = run.problemGroups.count
            return (count == 1 ? String(localized: "1 problem needs you") : String(localized: "\(count) problems need you"), true)
        }
        guard let stall = studio.stall, let text = stall.stageNote else { return nil }
        return (text, stall.isWarning)
    }

    /// At Plan, the design project Start will use; then the run's.
    private var design: (kind: DesignProjectKind, name: String?) {
        guard run.stage == .plan else { return (run.designKind, run.designName) }
        return (studio.designProject?.kind ?? .none, studio.designProject?.displayName)
    }

    private func who(_ step: AutopilotStage) -> String {
        switch step {
        case .plan: String(localized: "You and \(client)")
        case .waiting, .capture: captureWho
        case .pick: run.pickSkipNote ?? String(localized: "You")
        case .choose: chooseWho
        case .design: designWho
        case .localize: String(localized: "AppLocalizer, \(client)")
        case .watchPreview: watchWho
        case .ready:
            if run.stage == .ready { String(localized: "You · everything is waiting there") } else { String(localized: "You") }
        }
    }

    /// "You", or "Skipped: Claude’s recommendation" when the run doesn't
    /// stop to choose.
    private var chooseWho: String {
        if run.plan.stopsToChoose { return String(localized: "You") }
        return String(localized: "Skipped: Claude’s recommendation")
    }

    /// "Claude Design · Northpier Brand", "AppLocalizer’s starters".
    private var designWho: String {
        guard design.kind.usesDesignAI else { return String(localized: "AppLocalizer’s starters") }
        return [design.kind.title, design.name].compactMap(\.self).joined(separator: " · ")
    }

    /// "Skipped · no App Preview", "You · ask Claude Design for changes".
    private var watchWho: String {
        if let skipped = run.watchSkipNote(design: design.kind) { return skipped }
        return run.designKind.usesDesignAI ? String(localized: "You · ask \(run.designKind.title) for changes") : String(localized: "You")
    }

    /// "Skipped · reuses the Oct 28 captures", "Claude Code · records the
    /// App Preview", "Claude Code · Simulator".
    private var captureWho: String {
        if let skipped = run.captureSkipNote { return skipped }
        let client = run.clientName(assistant: assistant, startsSentence: true)
        return run.onlyRecords ? String(localized: "\(client) · records the App Preview") : String(localized: "\(client) · Simulator")
    }

    private func state(of step: AutopilotStage) -> AutopilotStageRow.State {
        let current = run.stage.step
        if step.number < current.number { return .done }
        guard step == current else { return .upcoming }
        // No spinner while nobody works on it.
        if run.stage.isRunning { return studio.stall == nil ? .running : .current }
        return run.stage.waitsForPerson || run.stage == .ready ? .yourTurn : .current
    }
}
