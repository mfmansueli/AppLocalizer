//
//  GuidedPlanStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Step 3, Plan: the run as a timeline (who does what, how long, where
/// it stops for the person), the screens under the capture line, and
/// fewer stops or more control. A device this Mac can't capture comes
/// first.
struct GuidedPlanStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let assistant: String?
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        let plan = run.plan
        let client = run.clientName(assistant: assistant)
        let rows = GuidedPlanTimeline.rows(
            plan: plan, client: client, design: studio.designProject?.kind ?? .none,
            brand: studio.shotStyleBrand, kept: plan.reusesCaptures ? run.keptCaptureCount : 0
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
                if let simulators = launcher?.simulators, !simulators.missing(in: plan.runDisplays).isEmpty {
                    AutopilotMacCheckView(studio: studio, plan: plan, simulators: simulators)
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
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .onAppear { studio.fillHeaderTemplates() }
        // The devices this Mac can't capture show before Start.
        .task {
            if let simulators = launcher?.simulators, simulators.inventory == nil { await simulators.check() }
        }
    }
}
