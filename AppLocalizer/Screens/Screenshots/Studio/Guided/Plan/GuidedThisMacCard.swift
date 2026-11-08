//
//  GuidedThisMacCard.swift
//  AppLocalizer
//

import SwiftUI

/// Plan · This Mac: one row per device in the run with its simulator,
/// before Start. A simulator to make (Make the Simulator) or a platform to
/// install keeps Start disabled, and so does a helper too old to check
/// (Save the Helper Again…). iPhone Duo starts closed and AppLocalizer
/// opens it when the run needs it (`DuoWatcher`): Open Now opens it before
/// Start, and Accessibility, allowed once, lets AppLocalizer open it.
struct GuidedThisMacCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let simulators: MacSimulators
    /// The person asked AppLocalizer to start and open the Duo now.
    @State private var opensDuo = false

    var body: some View {
        let check = GuidedMacCheck(run: run, state: simulators.state)
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("This Mac")
                    .font(.callout.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if simulators.state == .checking { ProgressView().controlSize(.mini) }
                Text(check.summary)
                    .font(.callout.weight(check.summaryIsWarning ? .semibold : .regular))
                    .foregroundStyle(check.summaryIsWarning ? Palette.label : Palette.label2)
                    .accessibilityIdentifier("autopilot.mac.summary")
                Button("Check Again") { studio.checkSimulators() }
                    .controlSize(.small)
                    .disabled(simulators.working != nil || simulators.state == .checking)
                    .accessibilityIdentifier("autopilot.mac.check")
            }
            switch simulators.state {
            case .oldHelper:
                helperBanner(
                    String(localized: """
                    The helper on this Mac is older than AppLocalizer, so it can’t check the simulators before Start. \
                    Save it again; it takes a few seconds.
                    """),
                    button: String(localized: "Save the Helper Again…"), isWarning: true
                )
            case .noHelper:
                helperBanner(
                    String(localized: "Install the helper so AppLocalizer can check this Mac’s simulators before starting."),
                    button: String(localized: "Install Helper…"), isWarning: false
                )
            case let .failed(reason):
                Text(reason)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.mac.message")
            default:
                rows(check)
            }
            if let failure = simulators.failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.mac.failure")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GuidedSelectableCard())
        .task { await simulators.check() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.mac")
    }

    private func helperBanner(_ text: String, button: String, isWarning: Bool) -> some View {
        HStack(spacing: Spacing.small) {
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("autopilot.mac.message")
            Button(button) { studio.installHelperAndCheck() }
                .controlSize(.small)
                .accessibilityIdentifier("autopilot.mac.helper")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, Spacing.small)
        .background(isWarning ? Palette.warningTint.opacity(0.18) : Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner))
    }

    private func rows(_ check: GuidedMacCheck) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(check.displays.enumerated()), id: \.element) { index, display in
                if index > 0 { Divider() }
                row(display, check: check)
            }
        }
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.mac.rows")
    }

    private func row(_ display: ScreenshotDisplayType, check: GuidedMacCheck) -> some View {
        let status = check.status(for: display)
        let isWorking = simulators.working == display
        let watchesDuo = status?.canCapture == true && display.simulatorStartsClosed
        let isMissing = check.missing.contains(display)
        let isFine = status != nil && !isMissing && (!watchesDuo || simulators.duo.state == .open)
        return HStack(alignment: .center, spacing: 10) {
            Text(display.title)
                .font(.callout.weight(.semibold))
                .frame(width: 110, alignment: .leading)
            HStack(spacing: Spacing.xSmall) {
                if isWorking || (watchesDuo && simulators.duo.state.isWorking) { ProgressView().controlSize(.mini) }
                Text(text(display, status: status, check: check, watchesDuo: watchesDuo, isWorking: isWorking))
                    .font(.callout.weight(isMissing ? .semibold : .regular))
                    .foregroundStyle(watchesDuo && !isFine ? Palette.label2 : Palette.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.mac.\(display.mcpValue).status")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            button(display, status: status, watchesDuo: watchesDuo, isWorking: isWorking)
            if isFine {
                Image(systemName: "checkmark")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Palette.positive)
                    .accessibilityLabel(Text("Ready"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        // `.contain`, not `.combine`: the row's button (Install, Make the
        // Simulator, Open Now…) stays a button of its own.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.mac.\(display.mcpValue)")
        .task(id: [watchesDuo, opensDuo]) {
            // While the plan is looked at: whether it's open, and a stuck
            // one restarted. It's started and opened once the run needs
            // it, or the person asks.
            guard watchesDuo else { return }
            await simulators.duo.watch(mayStart: opensDuo)
        }
    }

    /// "iPhone 17 Pro Max · iOS 27.0", "iPhone Duo · iOS 27.2 · closed:
    /// AppLocalizer opens it when the run needs it".
    private func text(
        _ display: ScreenshotDisplayType, status _: SimulatorStatus?, check: GuidedMacCheck, watchesDuo: Bool, isWorking: Bool
    ) -> String {
        if isWorking { return simulators.progress ?? String(localized: "Starting…") }
        let detail = check.detail(for: display, appName: studio.app.name)
        guard watchesDuo else { return detail }
        switch simulators.duo.state {
        case .open:
            return detail + " · " + String(localized: "open")
        case .unknown, .closed, .notRunning, .closedForScreens:
            return detail + " · " + String(localized: "closed: AppLocalizer opens it when the run needs it")
        case .needsAccessibility:
            return String(localized: """
            Closed. Allow AppLocalizer in Privacy & Security › Accessibility once, and it opens iPhone Duo itself; \
            it only presses Open in Device Hub.
            """)
        default:
            return detail + " · " + simulators.duo.state.summary
        }
    }

    @ViewBuilder
    private func button(_ display: ScreenshotDisplayType, status: SimulatorStatus?, watchesDuo: Bool, isWorking: Bool) -> some View {
        if isWorking {
            EmptyView()
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

    /// What the Duo's row offers: open it now, or what lets AppLocalizer
    /// open it.
    @ViewBuilder
    private var duoButton: some View {
        switch simulators.duo.state {
        case .closed, .notRunning, .unknown:
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
}
