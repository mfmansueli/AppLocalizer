//
//  AutopilotMacCheckView.swift
//  AppLocalizer
//

import SwiftUI

/// This Mac, before Start: whether each planned device has a simulator to
/// capture on, and the fix when it doesn't — install the platform's
/// simulator, make the simulator, or save the helper that checks.
struct AutopilotMacCheckView: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let simulators: MacSimulators

    var body: some View {
        AutopilotOptionGroup(title: String(localized: "This Mac")) {
            if let message = simulators.message {
                HStack(spacing: Spacing.small) {
                    if simulators.state == .checking || simulators.state == .unknown { ProgressView().controlSize(.small) }
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("autopilot.mac.message")
                    Spacer(minLength: 0)
                    helperButton
                }
            } else {
                ForEach(plan.displayTypes, id: \.self) { display in
                    row(display)
                }
            }
            if let failure = simulators.failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.mac.failure")
            }
        }
        .overlay(alignment: .topTrailing) {
            Button("Check Again") { studio.checkSimulators() }
                .controlSize(.small)
                .disabled(simulators.working != nil || simulators.state == .checking)
                .padding(Spacing.small)
                .accessibilityIdentifier("autopilot.mac.check")
        }
        .task { await simulators.check() }
        .accessibilityIdentifier("autopilot.mac")
    }

    @ViewBuilder
    private var helperButton: some View {
        switch simulators.state {
        case .noHelper:
            Button("Install Helper…") { studio.installHelperAndCheck() }
                .controlSize(.small)
        case .oldHelper:
            Button("Save the Helper Again…") { studio.installHelperAndCheck() }
                .controlSize(.small)
        default:
            EmptyView()
        }
    }

    private func row(_ display: ScreenshotDisplayType) -> some View {
        let status = simulators.status(for: display)
        let isWorking = simulators.working == display
        let isReady = status?.canCapture == true
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isReady ? Palette.positive : Palette.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(display.title).font(.callout.weight(.medium))
                Text(isWorking ? simulators.progress ?? String(localized: "Starting…") : status?.detail ?? "")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("autopilot.mac.\(display.mcpValue)")
            Spacer(minLength: 0)
            if isWorking {
                ProgressView().controlSize(.small)
            } else if let platform = status?.platformToInstall {
                Button("Install the \(platform) Simulator") { studio.installSimulator(for: display) }
                    .controlSize(.small)
                    .disabled(simulators.working != nil)
                    .help(Text("Downloads it with xcodebuild -downloadPlatform \(platform) (several GB), then makes the simulator."))
                    .accessibilityIdentifier("autopilot.mac.install")
            } else if case .canMake = status {
                Button("Make the Simulator") { studio.makeSimulator(for: display) }
                    .controlSize(.small)
                    .disabled(simulators.working != nil)
                    .accessibilityIdentifier("autopilot.mac.make")
            }
        }
    }
}
