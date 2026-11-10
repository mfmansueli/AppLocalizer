//
//  GuidedPlanStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Step 3, Plan: what the assistant sent for this plan outside a run, the
/// run as a timeline (who does what, how long, where it stops for the
/// person), the screens under the capture line, fewer stops or more
/// control with the simulator options, and This Mac: each device's
/// simulator before Start.
struct GuidedPlanStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let assistant: String?
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        let plan = run.plan
        let client = run.clientName(assistant: assistant)
        let rows = GuidedPlanTimeline.rows(
            plan: plan, client: client, design: studio.plannedDesignKind,
            brand: studio.shotStyleBrand, kept: run.capturesKeptAtStart,
            gaps: studio.interfaceGaps(for: plan), app: studio.app.name
        )
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    Text("Here’s the plan")
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("autopilot.guided.title")
                    Text("Autopilot runs on its own and stops only where it says \(Text("You").fontWeight(.semibold)).")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
                let proposals = studio.planProposals
                if proposals.isWaiting {
                    AutopilotPlanChangesCard(studio: studio, run: run, proposals: proposals)
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        if row.kind == .capture, !run.skipsCapture {
                            GuidedTimelineRowView(row: row) {
                                GuidedScreensFold(studio: studio, run: run, client: client)
                            }
                        } else {
                            GuidedTimelineRowView(row: row)
                        }
                        if row.id != rows.last?.id { Divider().padding(.leading, Spacing.large) }
                    }
                }
                .padding(.vertical, Spacing.xxSmall)
                .modifier(GuidedSelectableCard(padding: 0))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("autopilot.guided.plan.timeline")
                GuidedStopsCard(studio: studio, run: run, assistant: assistant)
                if let simulators = launcher?.simulators, GuidedMacCheck.applies(to: run) {
                    GuidedThisMacCard(studio: studio, run: run, simulators: simulators)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .onAppear { studio.fillHeaderTemplates() }
        // Start waits until each device's simulator is known.
        .task {
            if let simulators = launcher?.simulators, simulators.inventory == nil { await simulators.check() }
        }
    }
}
