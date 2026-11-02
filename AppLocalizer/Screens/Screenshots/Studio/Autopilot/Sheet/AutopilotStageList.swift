//
//  AutopilotStageList.swift
//  AppLocalizer
//

import SwiftUI

/// The seven stages, who does each, and where the run is; then what's
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
                            who: who(step),
                            problem: step == run.stage.step ? problemText : nil,
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
    /// is working on it any more.
    private var problemText: String? {
        if run.stage.step == .capture, !run.openProblems.isEmpty {
            let count = run.problemGroups.count
            return count == 1 ? String(localized: "1 problem needs you") : String(localized: "\(count) problems need you")
        }
        switch studio.stall {
        case nil: return nil
        case .quiet: return String(localized: "Nothing new for a while")
        case .ended, .notRunning: return String(localized: "Claude Code stopped")
        }
    }

    /// At Plan, the design project Start will use; then the run's.
    private var design: (kind: DesignProjectKind, name: String?) {
        guard run.stage == .plan else { return (run.designKind, run.designName) }
        return (studio.designProject?.kind ?? .none, studio.designProject?.displayName)
    }

    private func who(_ step: AutopilotStage) -> String {
        switch step {
        case .plan: String(localized: "You and \(client)")
        case .waiting, .capture: String(localized: "\(run.clientName(assistant: assistant, startsSentence: true)) · Simulator")
        case .pick, .choose: String(localized: "You")
        case .design:
            if design.kind.usesDesignAI {
                [design.kind.title, design.name].compactMap(\.self).joined(separator: " · ")
            } else {
                String(localized: "AppLocalizer’s starters")
            }
        case .localize: String(localized: "AppLocalizer, \(client)")
        case .ready:
            if run.stage == .ready { String(localized: "You · everything is waiting there") } else { String(localized: "You") }
        }
    }

    private func state(of step: AutopilotStage) -> AutopilotStageRow.State {
        let current = run.stage.step
        if step.number < current.number { return .done }
        guard step == current else { return .upcoming }
        if run.stage.isRunning { return .running }
        return run.stage.waitsForPerson || run.stage == .ready ? .yourTurn : .current
    }
}
