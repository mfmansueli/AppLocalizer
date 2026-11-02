//
//  AutopilotMacCheckView.swift
//  AppLocalizer
//

import SwiftUI

/// This Mac, before Start: whether each planned device has a simulator to
/// capture on, and the fix when it doesn't — install the platform's
/// simulator, make the simulator, or save the helper that checks. iPhone
/// Duo's starts closed and AppLocalizer opens it when the run needs it
/// (`DuoWatcher`), so it says whether it's open, and what lets AppLocalizer
/// open it when it can't yet: Accessibility, the helper, or Device Hub.
/// Open Now opens it before Start.
struct AutopilotMacCheckView: View {
    @Bindable var studio: ScreenshotStudioModel
    let plan: AutopilotPlan
    let simulators: MacSimulators
    /// The person asked AppLocalizer to start and open the Duo now.
    @State private var opensDuo = false

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

    /// iPhone Duo is open, or AppLocalizer opens it when the run needs it;
    /// not when the person has something to do first.
    private var duoIsFine: Bool {
        !simulators.duo.state.waitsForPerson
    }

    /// "Closed: AppLocalizer opens it when the run needs it."
    private var duoText: String {
        switch simulators.duo.state {
        case .unknown:
            String(localized: "It starts closed: AppLocalizer opens it when the run needs it.")
        case .noHelper, .oldHelper, .failed:
            String(localized: "It starts closed.") + " " + simulators.duo.state.summary
        case .open:
            String(localized: "Open: ready to capture.")
        case .closed:
            String(localized: "Closed: AppLocalizer opens it when the run needs it.")
        default:
            simulators.duo.state.summary
        }
    }

    /// What the Duo's row offers: open it now, or what lets AppLocalizer
    /// open it.
    @ViewBuilder
    private var duoButton: some View {
        switch simulators.duo.state {
        case .closed, .notRunning:
            Button("Open Now") { opensDuo = true }
                .controlSize(.small)
                .help(Text("AppLocalizer starts iPhone Duo if it isn’t running and presses Open in its window in Device Hub."))
                .accessibilityIdentifier("autopilot.mac.openDuo")
        case .needsAccessibility:
            Button("Open Accessibility Settings") { AccessibilitySettings.open() }
                .controlSize(.small)
                .accessibilityIdentifier("autopilot.mac.accessibility")
        case .helperCantOpen:
            Button("Save the Helper Again…") { studio.installHelperAndCheck() }
                .controlSize(.small)
                .accessibilityIdentifier("autopilot.mac.duoHelper")
        case .noHelper, .oldHelper, .failed, .couldntOpen, .stuck:
            if DeviceHub.url != nil {
                Button("Open in Device Hub") { DeviceHub.open(udid: simulators.inventory?.simulator(for: .iPhoneDuo)?.udid) }
                    .controlSize(.small)
                    .help(Text(DeviceHub.openingSteps))
                    .accessibilityIdentifier("autopilot.mac.deviceHub")
            }
        default:
            EmptyView()
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
            .task(id: [watchesDuo, opensDuo]) {
                // While the plan is looked at: whether it's open, and a
                // stuck one restarted. It's started and opened once the run
                // needs it, or the person asks.
                guard watchesDuo else { return }
                await simulators.duo.watch(mayStart: opensDuo)
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
            } else if watchesDuo {
                duoButton
            }
        }
    }
}
