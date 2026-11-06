//
//  AutopilotSimulatorOptions.swift
//  AppLocalizer
//

import SwiftUI

/// How Simulator is set up for the captures: each language, the status
/// bar, sample data (in each language), light appearance, permissions,
/// and the commands a fix added. The classic plan's Simulator group and
/// the guided plan's Change… show the same rows.
struct AutopilotSimulatorOptions: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The connected assistant that can run Xcode.
    let assistant: String?

    var body: some View {
        AutopilotOptionRow(
            title: String(localized: "Capture the app in each language"),
            detail: String(localized: "Launches with -AppleLanguages; otherwise \(studio.primaryLocale.shortName) captures are reused under translated captions"),
            isOn: planBinding(\.capturesEachLanguage)
        )
        .accessibilityIdentifier("autopilot.plan.eachLanguage")
        AutopilotOptionRow(
            title: String(localized: "Status bar at 9:41, full battery and signal"),
            detail: "xcrun simctl status_bar override",
            isOn: planBinding(\.simulator.overridesStatusBar)
        )
        AutopilotOptionRow(
            title: String(localized: "Sample data"),
            detail: run.plan.simulator.sampleDataSteps.isEmpty
                ? String(localized: "\(run.clientName(assistant: assistant, startsSentence: true)) finds the app’s sample-data switch")
                : run.plan.simulator.sampleDataSteps,
            isOn: planBinding(\.simulator.usesSampleData)
        )
        AutopilotOptionRow(
            title: String(localized: "Sample data in each language"),
            detail: String(localized: "Entries, names and places in the capture’s language, not just the interface"),
            isOn: planBinding(\.simulator.sampleDataInEachLanguage),
            isLocked: !run.plan.simulator.usesSampleData || !run.plan.capturesEachLanguage
        )
        .accessibilityIdentifier("autopilot.plan.sampleDataLanguage")
        AutopilotOptionRow(
            title: String(localized: "Light appearance, no notifications"),
            detail: String(localized: "Any prompt is answered before capturing, so no alert lands in a screenshot"),
            isOn: planBinding(\.simulator.lightAppearance)
        )
        AutopilotOptionRow(
            title: String(localized: "Permissions granted before capturing"),
            detail: "xcrun simctl privacy grant all",
            isOn: planBinding(\.simulator.grantsPermissions)
        )
        ForEach(run.plan.simulator.extraCommands, id: \.self) { command in
            AutopilotOptionRow(title: String(localized: "Added by a fix"), detail: command, isOn: .constant(true), isLocked: true)
        }
    }

    private func planBinding(_ keyPath: WritableKeyPath<AutopilotPlan, Bool>) -> Binding<Bool> {
        Binding {
            run.plan[keyPath: keyPath]
        } set: { value in
            studio.updatePlan { $0[keyPath: keyPath] = value }
        }
    }
}
