//
//  GuidedStopsCard.swift
//  AppLocalizer
//

import SwiftUI

/// Fewer stops, or more control: choose the look for the person (one
/// stop, at the end), pick the captures themselves, how Simulator is set
/// up (Change… shows every option), and the design source.
struct GuidedStopsCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let assistant: String?

    var body: some View {
        let plan = run.plan
        let client = run.clientName(assistant: assistant)
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Fewer stops, or more control").font(.callout.weight(.semibold))
            if GuidedPlanTimeline.hasLookToChoose(plan) {
                Toggle(isOn: Binding { !plan.stopsToChoose } set: { value in studio.updatePlan { $0.stopsToChoose = !value } }) {
                    Text("Choose the look for me · use \(GuidedPick.label(design: design)) and stop only at the end")
                }
                .accessibilityIdentifier("autopilot.guided.plan.choosesForMe")
            }
            if plan.makesScreenshots || !plan.artworkTargets.isEmpty {
                Toggle(isOn: Binding { plan.stopsToPick } set: { value in studio.updatePlan { $0.stopsToPick = value } }) {
                    Text("Let me pick the captures myself · otherwise \(client) picks the best of 3 tries")
                }
                .accessibilityIdentifier("autopilot.guided.plan.picksCaptures")
            }
            if !plan.runDisplays.isEmpty {
                Button("\(GuidedPlanTimeline.simulatorLine(plan)) · Change…") { studio.guided.showsSimulator.toggle() }
                    .buttonStyle(.link)
                    .font(.callout)
                    .accessibilityIdentifier("autopilot.guided.plan.simulator")
                    .popover(isPresented: $studio.guided.showsSimulator, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text("Simulator").font(.headline)
                            AutopilotSimulatorOptions(studio: studio, run: run, assistant: assistant)
                        }
                        .padding(Spacing.large)
                        .frame(width: 440)
                        .accessibilityIdentifier("autopilot.guided.plan.simulatorOptions")
                    }
            }
            designLine
        }
        .toggleStyle(.checkbox)
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GuidedSelectableCard())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.plan.stops")
    }

    private var design: DesignProjectKind { studio.designProject?.kind ?? .none }

    /// "Design: Claude Design · Northpier Brand", or AppLocalizer's
    /// starters with Connect….
    @ViewBuilder
    private var designLine: some View {
        if let project = studio.designProject {
            Text("Design: \(project.kind.title) · \(project.displayName)")
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("autopilot.guided.plan.design")
        } else {
            HStack(spacing: Spacing.xSmall) {
                Text("Design: AppLocalizer’s starters, colored from the app icon")
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.guided.plan.design")
                Button("Connect…") { studio.isDesignProjectPresented = true }
                    .controlSize(.small)
                    .accessibilityIdentifier("autopilot.guided.plan.connectDesign")
            }
        }
    }
}
