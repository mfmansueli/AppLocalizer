//
//  AutopilotPlanChangesCard.swift
//  AppLocalizer
//

import SwiftUI

/// At the top of Plan: what the assistant sent for this plan outside a
/// run (Alba's 1.1 steps, sent at Review & Push). Each change waits for
/// Accept or Reject; the screens it suggested are under the screens, with
/// Add to Plan, and Show Screens opens them.
struct AutopilotPlanChangesCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let proposals: AutopilotPlanProposals

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Sent for this plan")
                .font(.callout.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(proposals.changes.enumerated()), id: \.element.id) { index, change in
                if index > 0 { Divider() }
                AutopilotPlanChangeView(studio: studio, plan: run.plan, change: change)
            }
            if proposals.openScreenCount > 0 {
                if !proposals.changes.isEmpty { Divider() }
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    Text(screensText)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("autopilot.plan.changes.screens")
                    if !studio.guided.showsScreens {
                        Button("Show Screens") { studio.guided.showsScreens = true }
                            .controlSize(.small)
                            .accessibilityIdentifier("autopilot.plan.changes.showScreens")
                    }
                }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.machineTranslatedTint.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.plan.changes")
    }

    /// "2 screens suggested for the set: add the ones you want under the
    /// screens." Apple Watch's wait while the plan leaves it out.
    private var screensText: String {
        let set = proposals.screens(on: .iPhone).reduce(0) { $0 + $1.open.count }
        let watch = proposals.screens(on: .watch).reduce(0) { $0 + $1.open.count }
        var parts: [String] = []
        if set > 0 { parts.append(set == 1 ? String(localized: "1 screen for the set") : String(localized: "\(set) screens for the set")) }
        if watch > 0 {
            parts.append(watch == 1 ? String(localized: "1 Apple Watch screen") : String(localized: "\(watch) Apple Watch screens"))
        }
        var text = String(localized: "Suggested: \(parts.joined(separator: ", ")). Add the ones you want under the screens.")
        if watch > 0, !run.plan.displayTypes.contains(.watch) {
            text += " " + String(localized: "Turn on Apple Watch to add its screens.")
        }
        return text
    }
}
