//
//  AutopilotLaunchStatus.swift
//  AppLocalizer
//

import SwiftUI

/// Capture, when AppLocalizer started Claude Code for the run: what it's
/// doing now, with Show Output (over the Autopilot sheet) and Stop, and
/// what it may run.
struct AutopilotLaunchStatus: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: ClaudeCodeRun

    @State private var showsOutput = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            ClaudeCodeRunStatusView(run: run, onShowOutput: { showsOutput = true }, onRetried: { studio.launchedRunID = $0 })
            Text("It may run xcodebuild and xcrun, and send captures to AppLocalizer. Anything else is refused and listed here.")
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(isPresented: $showsOutput) {
            ClaudeCodeRunOutputSheet(runID: run.id)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.launch")
    }
}
