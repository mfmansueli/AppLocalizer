//
//  AutopilotCancelRunButton.swift
//  AppLocalizer
//

import SwiftUI

/// Cancel Run… from Capture through Watch the App Preview: asks first,
/// then stops what this Mac makes and Claude Code, and goes back to the
/// plan with the captures and picks.
struct AutopilotCancelRunButton: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    var identifier = "autopilot.cancelRun.later"
    @State private var isAsking = false

    var body: some View {
        Button("Cancel Run…") { isAsking = true }
            .buttonBorderShape(.capsule)
            .help(Text("Stop this run and go back to the plan"))
            .accessibilityIdentifier(identifier)
            .confirmationDialog(Text("Cancel this run?"), isPresented: $isAsking) {
                Button("Cancel Run", role: .destructive) { cancel() }
                    .accessibilityIdentifier("autopilot.cancelRun.confirm")
                Button("Keep Going", role: .cancel) {}
                    .accessibilityIdentifier("autopilot.cancelRun.keep")
            } message: {
                Text(Self.message(for: run))
            }
    }

    /// While capturing nothing is being made here yet: Claude Code stops.
    private func cancel() {
        if run.stage == .capture { studio.stop() } else { studio.cancelRun() }
    }

    /// What stays and what stops.
    static func message(for run: AutopilotRun) -> String {
        if run.stage == .capture {
            return String(localized: """
            Claude Code stops capturing and the run goes back to the plan. The captures so far stay for the next \
            start. Nothing was sent to App Store Connect.
            """)
        }
        var parts = [String(localized: "AppLocalizer stops what it’s making and Claude Code stops. The captures and picks stay for the next start.")]
        if let version = run.templateVersion {
            parts.append(String(localized: "Template v\(version) is already saved and stays in the set’s history."))
        }
        parts.append(String(localized: "Nothing was sent to App Store Connect."))
        return parts.joined(separator: " ")
    }
}
