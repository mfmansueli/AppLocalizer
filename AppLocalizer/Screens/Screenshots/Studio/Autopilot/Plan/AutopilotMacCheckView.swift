//
//  AutopilotMacCheckView.swift
//  AppLocalizer
//

import SwiftUI

/// This Mac, before Start: whether each planned device has a simulator to
/// capture on, and the fix when it doesn't — install the platform's
/// simulator, make the simulator, or save the helper that checks. iPhone
/// Duo's starts closed, so it says whether it's open, watching it
/// (`DuoWatcher`), and to open it in Device Hub.
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

    /// iPhone Duo is open, or AppLocalizer can't see it (an older helper)
    /// and only says it starts closed.
    private var duoIsFine: Bool {
        let state = simulators.duo.state
        return state == .open || !state.isWatched
    }

    /// "Closed: open it in Device Hub before Start, …".
    private var duoText: String {
        let starts = String(localized: "It starts closed: open it in Device Hub before Start.")
        switch simulators.duo.state {
        case .unknown:
            return starts
        case .noHelper, .oldHelper, .failed:
            return starts + " " + simulators.duo.state.summary
        case .open:
            return String(localized: "Open: ready to capture.")
        case .closed:
            return String(localized: "Closed: open it in Device Hub before Start, or while the run captures the other devices.")
        default:
            return simulators.duo.state.summary
        }
    }

    private func row(_ display: ScreenshotDisplayType) -> some View {
        let status = simulators.status(for: display)
        let isWorking = simulators.working == display
        let isReady = status?.canCapture == true
        let watchesDuo = isReady && display.simulatorStartsClosed
        let isFine = isReady && (!watchesDuo || duoIsFine)
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Image(systemName: isFine ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isFine ? Palette.positive : Palette.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(display.title).font(.callout.weight(.medium))
                Text(isWorking ? simulators.progress ?? String(localized: "Starting…") : status?.detail ?? "")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                if watchesDuo {
                    HStack(spacing: Spacing.xSmall) {
                        if simulators.duo.state.isWorking { ProgressView().controlSize(.mini) }
                        Text(duoText)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("autopilot.mac.\(display.mcpValue)")
            .task(id: watchesDuo) {
                // While the plan is looked at: whether it's open, and a
                // stuck one restarted. It's started only once the run needs it.
                guard watchesDuo else { return }
                _ = await simulators.duo.watch(mayStart: false, untilOpened: false)
            }
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
            } else if isReady, display.simulatorStartsClosed, DeviceHub.url != nil {
                Button("Open Device Hub") { DeviceHub.open() }
                    .controlSize(.small)
                    .help(Text(DeviceHub.openingSteps))
                    .accessibilityIdentifier("autopilot.mac.deviceHub")
            }
        }
    }
}
