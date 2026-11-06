//
//  GuidedScreensFold.swift
//  AppLocalizer
//

import SwiftUI

/// Under the capture line: "17 screens from LumenUITests · Show", and,
/// shown, the screens and how the assistant reaches each, Add a Screen…,
/// Suggest Screens, the Duo's screens and whether to reuse the last
/// captures.
struct GuidedScreensFold: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let client: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Button(studio.guided.showsScreens ? String(localized: "Hide screens") : String(localized: "\(summary) · Show")) {
                studio.guided.showsScreens.toggle()
            }
            .buttonStyle(.link)
            .font(.caption)
            .accessibilityValue(Text(studio.guided.showsScreens ? "Shown" : "Hidden"))
            .accessibilityIdentifier("autopilot.guided.plan.screens.toggle")
            if studio.guided.showsScreens {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    AutopilotOptionRow(
                        title: String(localized: "\(client) picks the screens"),
                        detail: String(localized: "It reads the project and replaces these with the screens that show \(studio.app.name) best, before capturing. Off, it keeps yours and writes their steps."),
                        isOn: Binding { run.plan.choosesScreens } set: { value in studio.updatePlan { $0.choosesScreens = value } }
                    )
                    .accessibilityIdentifier("autopilot.guided.plan.choosesScreens")
                    AutopilotPlanTable(studio: studio, plan: run.plan, client: client, isEditable: true)
                        .fixedSize(horizontal: false, vertical: true)
                    if run.plan.makesScreenshots, run.plan.plansDuo {
                        AutopilotDuoChoiceRow(studio: studio, plan: run.plan)
                    }
                    if let reuse = studio.reuseTitle, studio.capturesMatter(run.plan) {
                        Toggle(reuse, isOn: Binding { run.plan.reusesCaptures } set: { studio.setReusesCaptures($0) })
                            .toggleStyle(.checkbox)
                            .font(.callout)
                            .help(Text(studio.capturesNote(run.plan, client: client)))
                            .accessibilityIdentifier("autopilot.guided.plan.reuse")
                    }
                    HStack(spacing: Spacing.xSmall) {
                        Button("Add a Screen…") { studio.openScreenForm() }
                            .disabled(studio.plansMaximumScreens)
                            .accessibilityIdentifier("autopilot.guided.plan.addScreen")
                        Button {
                            studio.suggestScreens()
                        } label: {
                            Label("Suggest Screens", systemImage: "sparkles")
                        }
                        .disabled(studio.plansMaximumScreens || run.screenRequest != nil)
                        .accessibilityIdentifier("autopilot.guided.plan.suggestScreens")
                    }
                    .controlSize(.small)
                }
                .padding(Spacing.small)
                .background(Palette.content, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            }
        }
        .padding(.top, Spacing.xxSmall)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.plan.screens")
    }

    /// "17 screens from LumenUITests/ScreenshotTests.swift", "12 screens";
    /// "Claude Code picks the screens" when there are none yet.
    private var summary: String {
        let plan = run.plan
        let count = plan.screens.count + plan.displayTypes.filter(\.hasOwnScreens).reduce(0) { $0 + plan.screens(on: $1).count }
        guard count > 0 else { return String(localized: "\(client) picks the screens") }
        let screens = count == 1 ? String(localized: "1 screen") : String(localized: "\(count) screens")
        guard let file = plan.writtenFrom else { return screens }
        return String(localized: "\(screens) from \(file)")
    }
}
