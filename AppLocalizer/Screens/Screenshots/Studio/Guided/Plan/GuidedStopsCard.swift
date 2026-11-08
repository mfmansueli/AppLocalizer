//
//  GuidedStopsCard.swift
//  AppLocalizer
//

import SwiftUI

/// Fewer stops, or more control: choose the look for the person (one
/// stop, at the end), pick the captures themselves, how Simulator is set
/// up (Change… opens every option in place), and the design source.
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
            if !plan.runDisplays.isEmpty, !run.skipsCapture {
                let isOpen = studio.guided.showsSimulator
                Button(isOpen ? String(localized: "Hide Simulator options") : "\(GuidedPlanTimeline.simulatorLine(plan)) · " + String(localized: "Change…")) {
                    studio.guided.showsSimulator.toggle()
                }
                .buttonStyle(.link)
                .font(.callout)
                .accessibilityValue(Text(isOpen ? "expanded" : "collapsed"))
                .accessibilityIdentifier("autopilot.guided.plan.simulator")
                if isOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        AutopilotSimulatorOptions(studio: studio, run: run, assistant: assistant)
                    }
                    .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
                    .accessibilityElement(children: .contain)
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

    private var design: DesignProjectKind { studio.plannedDesignKind }

    /// "Design: Claude Design · Northpier Brand"; without a design project,
    /// the assistant designing from the app's own design (or AppLocalizer's
    /// starters when it's turned off), with Connect….
    @ViewBuilder
    private var designLine: some View {
        if let project = studio.designProject {
            Text("Design: \(project.kind.title) · \(project.displayName)")
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("autopilot.guided.plan.design")
        } else {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Toggle(isOn: Binding { run.plan.assistantDesignsLooks == true } set: { value in
                    studio.updatePlan { $0.assistantDesignsLooks = value }
                }) {
                    Text("Design the screenshot looks from the app’s own design · \(GuidedStopsCard.designDetail(run.plan, client: run.clientName(assistant: assistant)))")
                }
                .accessibilityIdentifier("autopilot.guided.plan.assistantDesignsLooks")
                HStack(spacing: Spacing.xSmall) {
                    Text(GuidedStopsCard.designSource(run.plan))
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("autopilot.guided.plan.design")
                    Button("Connect…") { studio.isDesignProjectPresented = true }
                        .controlSize(.small)
                        .accessibilityIdentifier("autopilot.guided.plan.connectDesign")
                }
            }
        }
    }

    /// What the toggle does, on or off.
    static func designDetail(_ plan: AutopilotPlan, client: String) -> String {
        plan.assistantDesignsLooks == true
            ? String(localized: "\(client) reads its design docs and theme, and \(DesignProjectKind.claudeDesign.title) designs 3 looks")
            : String(localized: "otherwise AppLocalizer’s starters, colored from the app icon")
    }

    /// The design source line without a design project.
    static func designSource(_ plan: AutopilotPlan) -> String {
        plan.assistantDesignsLooks == true
            ? String(localized: "Design: the app’s own, from its project · or connect a design project")
            : String(localized: "Design: AppLocalizer’s starters, colored from the app icon")
    }
}
