//
//  AutopilotSimulatorOptions.swift
//  AppLocalizer
//

import SwiftUI

/// How Simulator is set up for the captures, opened in place under the
/// plan's Simulator line: each language, the status bar, sample data in
/// each language, light appearance, permissions, and the commands a fix
/// added.
struct AutopilotSimulatorOptions: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    /// The connected assistant that can run Xcode.
    let assistant: String?

    var body: some View {
        let plan = run.plan
        let client = run.clientName(assistant: assistant)
        row(
            String(localized: "Capture the app in each language"),
            detail: String(localized: "Launches with -AppleLanguages; without it, \(studio.primaryLocale.shortName) captures would sit under translated captions"),
            isOn: planBinding(\.capturesEachLanguage), identifier: "autopilot.plan.eachLanguage", isFirst: true
        )
        row(
            String(localized: "Status bar at 9:41, full battery and signal"),
            detail: "xcrun simctl status_bar override",
            isOn: planBinding(\.simulator.overridesStatusBar), identifier: "autopilot.plan.statusBar"
        )
        row(
            plan.capturesEachLanguage ? String(localized: "Sample data in each language") : String(localized: "Sample data"),
            detail: sampleDataDetail(plan, client: client),
            isOn: sampleData, identifier: "autopilot.plan.sampleDataLanguage"
        )
        row(
            String(localized: "Light appearance, no notifications"),
            detail: String(localized: "Dark captures are made only if the look asks for them"),
            isOn: planBinding(\.simulator.lightAppearance), identifier: "autopilot.plan.lightAppearance"
        )
        row(
            String(localized: "Permissions granted before launch"),
            detail: String(localized: "Photos and notifications, so no alert covers a screen"),
            isOn: planBinding(\.simulator.grantsPermissions), identifier: "autopilot.plan.permissions"
        )
        ForEach(plan.simulator.extraCommands, id: \.self) { command in
            row(String(localized: "Added by a fix"), detail: command, isOn: .constant(true), isLocked: true)
        }
    }

    private func row(
        _ title: String, detail: String, isOn: Binding<Bool>, identifier: String? = nil, isFirst: Bool = false, isLocked: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            if !isFirst { Divider() }
            AutopilotOptionRow(title: title, detail: detail, isOn: isOn, isLocked: isLocked)
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .accessibilityIdentifier(identifier ?? "autopilot.plan.extraCommand")
        }
    }

    /// "Entries, names and places in the capture’s language, not just the
    /// interface; Claude Code finds the app’s sample-data switch".
    private func sampleDataDetail(_ plan: AutopilotPlan, client: String) -> String {
        let finds = plan.simulator.sampleDataSteps.isEmpty
            ? String(localized: "\(client) finds the app’s sample-data switch")
            : plan.simulator.sampleDataSteps
        guard plan.capturesEachLanguage else { return finds }
        return String(localized: "Entries, names and places in the capture’s language, not just the interface; \(finds)")
    }

    /// Sample data, in each language whenever the app is captured in each
    /// language: one switch for both.
    private var sampleData: Binding<Bool> {
        Binding {
            let simulator = run.plan.simulator
            return simulator.usesSampleData && (simulator.sampleDataInEachLanguage || !run.plan.capturesEachLanguage)
        } set: { value in
            studio.updatePlan {
                $0.simulator.usesSampleData = value
                $0.simulator.sampleDataInEachLanguage = value
            }
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
