//
//  AutopilotProblemCard.swift
//  AppLocalizer
//

import SwiftUI

/// A screen the assistant couldn't reach — the same screen in several
/// languages and devices for one cause, or a whole device this Mac can't
/// run: what happened, the fix proposed, and the ways out. Only a fix
/// that's a command joins the plan when retried; a change to the project or
/// a step for the person is shown as what to do first. A device without a
/// simulator offers to install it, or to leave the device out. iPhone
/// Duo's simulator starts closed: AppLocalizer opens it itself, restarts a
/// stuck one and tries its screens again once it's open (`DuoWatcher`,
/// watched by the capture stage), so the card says what it sees, and offers
/// only what lets it go on when AppLocalizer can't: Accessibility, the
/// helper, or Device Hub.
struct AutopilotProblemCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let group: AutopilotProblemGroup
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(summary)
                .fixedSize(horizontal: false, vertical: true)
            if group.wasRefused, let command = group.refusedCommand {
                code(command, identifier: "autopilot.problem.refused")
            }
            if watchesDuo {
                duoStatus
            } else if let fix = group.proposedFix {
                if let fixLabel {
                    Text(fixLabel)
                        .font(.callout.weight(.medium))
                }
                code(fix, identifier: "autopilot.problem.fix")
            }
            if let progress = installProgress {
                HStack(spacing: Spacing.small) {
                    ProgressView().controlSize(.small)
                    Text(progress).font(.caption).foregroundStyle(Palette.label2)
                }
                .accessibilityIdentifier("autopilot.problem.progress")
            }
            if let duoHelper { duoHelperRow(duoHelper) }
            buttons
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(group.wasRefused ? "autopilot.problem.refusedNote" : "autopilot.problem.note")
            }
        }
        .padding(Spacing.medium)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.dangerMark, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.problem")
        .task(id: group.id) {
            // A device-wide problem offers the fix this Mac needs.
            guard group.isDeviceWide, let simulators, simulators.inventory == nil else { return }
            await simulators.check()
        }
    }

    /// What AppLocalizer sees of iPhone Duo, in place of the assistant's
    /// fix: AppLocalizer opens it and restarts a stuck one itself.
    private var duoStatus: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            if duo?.isWorking == true { ProgressView().controlSize(.small) }
            Text(duoText)
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.problem.duo")
        }
    }

    /// Why to save the helper, on a line of its own: AppLocalizer can't see
    /// the Duo without it.
    private func duoHelperRow(_ state: DuoState) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(state.summary)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("autopilot.problem.duoHelperNote")
            Spacer(minLength: 0)
            Button(state == .noHelper ? "Install the Helper…" : "Save the Helper Again…") { studio.installHelperAndCheck() }
                .controlSize(.small)
                .fixedSize()
                .accessibilityIdentifier("autopilot.problem.duoHelper")
        }
    }

    /// The Duo's state when the helper can't look at it, or open it, yet.
    private var duoHelper: DuoState? {
        duo == .oldHelper || duo == .noHelper || duo == .helperCantOpen ? duo : nil
    }

    private var duoText: String {
        switch duo {
        case .closed?, .opening?, .spinner?, .notRunning?, .starting?:
            (duo?.summary ?? "") + " " + String(localized: "Once it’s open, the run captures it by itself.")
        case .helperCantOpen?:
            // The helper's row says why.
            String(localized: "iPhone Duo is closed.")
        case .open?:
            String(localized: "iPhone Duo is open, so something else stopped it: retry, or leave it out.")
        default:
            duo?.summary ?? ""
        }
    }

    private var buttons: some View {
        HStack(spacing: Spacing.small) {
            if opensInDeviceHub {
                if duo == .needsAccessibility {
                    Button("Open Accessibility Settings") { AccessibilitySettings.open() }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("autopilot.problem.accessibility")
                }
                // Only when AppLocalizer can't open it itself.
                if DeviceHub.url != nil, !watchesDuo || duo?.waitsForPerson == true {
                    Button("Open in Device Hub") { DeviceHub.open(udid: duoUDID) }
                        .buttonStyle(.borderedProminent)
                        .tint(duo == .needsAccessibility ? Palette.label2 : nil)
                        .accessibilityIdentifier("autopilot.problem.deviceHub")
                }
            } else if group.isDeviceWide, let helperTitle {
                Button(helperTitle) { studio.installHelperAndCheck() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("autopilot.problem.helper")
            } else if let platform = simulatorStatus?.platformToInstall {
                Button("Install the \(platform) Simulator") { studio.installSimulator(for: group.displayType) }
                    .buttonStyle(.borderedProminent)
                    .disabled(simulators?.working != nil)
                    .accessibilityIdentifier("autopilot.problem.install")
            } else if case .canMake = simulatorStatus {
                Button("Make the Simulator") { studio.makeSimulator(for: group.displayType) }
                    .buttonStyle(.borderedProminent)
                    .disabled(simulators?.working != nil)
                    .accessibilityIdentifier("autopilot.problem.make")
            }
            Button(retryTitle) {
                studio.resolve(group, with: .retryWithFix)
            }
            .buttonStyle(.borderedProminent)
            .tint(simulatorStatus?.canCapture == false || isMakeable || opensInDeviceHub ? Palette.label2 : nil)
            .accessibilityIdentifier("autopilot.problem.retry")
            if canKeepCapture {
                Button(group.isSingle ? String(localized: "Keep the Capture") : String(localized: "Keep the Captures")) {
                    studio.resolve(group, with: .keptCapture)
                }
                .accessibilityIdentifier("autopilot.problem.keep")
            }
            if canUsePrimaryCapture {
                Button("Use the \(primaryName) Capture") { studio.resolve(group, with: .usePrimaryCapture) }
                    .accessibilityIdentifier("autopilot.problem.usePrimary")
            }
            if group.isSingle, !group.isDeviceWide {
                Button("Upload One by Hand…") { studio.uploadingProblem = group.first }
                    .accessibilityIdentifier("autopilot.problem.upload")
            }
            if group.isDeviceWide, group.displayType != .iPhone {
                Button("Leave \(group.displayType.shortTitle) Out") { studio.leaveOut(group.displayType) }
                    .accessibilityIdentifier("autopilot.problem.leaveOut")
            }
        }
        .buttonBorderShape(.capsule)
        .controlSize(.small)
    }

    // MARK: - Text

    /// "Week, German on iPhone: …"; "Styles, 7 languages on iPhone and
    /// iPad: …"; "iPhone Duo: no screen can be captured. …".
    /// The headline in bold, then what happened and what waits.
    private var summary: AttributedString {
        var bold = AttributedString(headline)
        bold.inlinePresentationIntent = .stronglyEmphasized
        return bold + AttributedString("\(group.first.what) \(othersText)")
    }

    private var headline: String {
        if group.isDeviceWide { return String(localized: "\(group.displayType.title): no screen can be captured. ") }
        let place = String(localized: "\(screenName), \(languages) on \(devices)")
        if group.wasRefused { return String(localized: "\(place): a command wasn’t allowed. ") }
        return canKeepCapture
            ? String(localized: "\(place): captured, with a problem. ")
            : String(localized: "\(place): couldn’t reach the screen. ")
    }

    private var fixLabel: String? {
        if group.needsProjectChange { return String(localized: "What to change in the project:") }
        return group.fixIsCommand ? nil : String(localized: "What to do first:")
    }

    /// Only a command joins the plan.
    private var retryTitle: String {
        group.fixIsCommand ? String(localized: "Use the Fix and Retry") : String(localized: "Retry")
    }

    private var note: String? {
        if group.wasRefused {
            return String(localized: """
            Claude Code started by AppLocalizer may only run commands that start with xcodebuild, xcrun simctl and the like. \
            Change the project so it doesn’t need this command, then retry, or continue the run in Terminal, where you can allow it.
            """)
        }
        if duo == .needsAccessibility {
            return String(localized: """
            AppLocalizer uses it only to press Open in iPhone Duo’s window in Device Hub, and tries again every few seconds. \
            Leaving iPhone Duo out finishes the run without it.
            """)
        }
        if duo?.waitsForPerson == true {
            let then = String(localized: "Once it’s open, the run captures it by itself; leaving it out finishes the run without it.")
            return DeviceHub.openingSteps + " " + then
        }
        if watchesDuo {
            return String(localized: """
            AppLocalizer opens iPhone Duo in Device Hub itself and restarts it when it’s stuck; leaving it out finishes the run without it.
            """)
        }
        if opensInDeviceHub {
            return DeviceHub.openingSteps + " " + DeviceHub.restartSteps + " "
                + String(localized: "Then retry; leaving it out finishes the run without it.")
        }
        if group.isDeviceWide, helperTitle != nil {
            return String(localized: """
            AppLocalizer installs the simulator through its helper: save it, then Install appears here. Leaving the device \
            out finishes the run without it.
            """)
        }
        if group.isDeviceWide {
            return simulatorStatus?.platformToInstall != nil
                ? String(localized: """
                Installing downloads the simulator with xcodebuild (several GB) and makes the \(group.displayType.deviceName) simulator; \
                the run tries the device again when it’s done. Leaving it out finishes the run without it.
                """)
                : String(localized: "Retry once this Mac can run the \(group.displayType.deviceName) simulator, or leave it out to finish the run without it.")
        }
        if group.needsProjectChange {
            return String(localized: """
            This is a change to the project, not a command: make it, then retry. Claude Code started by AppLocalizer can’t \
            change files; Claude Code in Terminal can.
            """)
        }
        guard group.proposedFix != nil else { return nil }
        if !group.fixIsCommand { return String(localized: "This is a step for you, not a command to add to the plan: do it, then retry.") }
        return String(localized: "\(run.client ?? String(localized: "The assistant")) proposed the fix; retrying adds it to the plan so later runs don’t stop here.")
    }

    private func code(_ text: String, identifier: String) -> some View {
        Text(text)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .padding(Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .accessibilityIdentifier(identifier)
    }

    // MARK: - Facts

    /// The sheet's environment has it from the first render.
    private var simulators: MacSimulators? { launcher?.simulators }

    /// This Mac's simulator for a device-wide problem.
    private var simulatorStatus: SimulatorStatus? {
        group.isDeviceWide ? simulators?.status(for: group.displayType) : nil
    }

    /// The helper to save before AppLocalizer can install the simulator.
    private var helperTitle: String? {
        switch simulators?.state {
        case .noHelper: String(localized: "Install the Helper…")
        case .oldHelper: String(localized: "Save the Helper Again…")
        default: nil
        }
    }

    /// This Mac has the device's simulator, but it starts closed (iPhone
    /// Duo): AppLocalizer opens it. Without a helper that can look at it,
    /// the assistant's fix stays, as it says whether to open it or restart
    /// it, and the person opens it in Device Hub.
    private var opensInDeviceHub: Bool {
        group.isDeviceWide && group.displayType.simulatorStartsClosed && simulatorStatus?.canCapture == true
    }

    /// iPhone Duo as AppLocalizer last saw it, for its card.
    private var duo: DuoState? { opensInDeviceHub ? simulators?.duo.state : nil }

    /// Device Hub shows the Duo's own window, with its poses.
    private var duoUDID: String? { simulators?.inventory?.simulator(for: .iPhoneDuo)?.udid }

    /// AppLocalizer sees the Duo, so its status replaces the assistant's
    /// fix.
    private var watchesDuo: Bool { duo?.isWatched == true }

    private var isMakeable: Bool {
        if case .canMake = simulatorStatus { return true }
        return false
    }

    /// `xcodebuild`'s progress while this device's simulator installs.
    private var installProgress: String? {
        guard group.isDeviceWide, let simulators, simulators.working == group.displayType else { return nil }
        return simulators.progress ?? String(localized: "Starting…")
    }

    /// Every one of these screens was captured before the problem was
    /// reported (MB Admin's portrait iPad capture): the person can keep it.
    private var canKeepCapture: Bool {
        !group.isDeviceWide && group.problems.allSatisfy { run.hasCapture(for: $0.target) }
    }

    /// The primary language's captures of these screens are there to reuse.
    private var canUsePrimaryCapture: Bool {
        guard !group.isDeviceWide, !group.includes(locale: run.plan.primaryLocale) else { return false }
        return group.problems.allSatisfy { problem in
            let primary = AutopilotCaptureTarget(screenID: problem.target.screenID, displayType: problem.target.displayType, locale: run.plan.primaryLocale)
            return run.captures.contains { $0.target == primary }
        }
    }

    private var screenName: String { run.plan.screen(id: group.screenID)?.name ?? group.screenID }
    private var primaryName: String { Self.name(of: run.plan.primaryLocale) }

    /// "Korean", "Korean and German", or "7 languages".
    private var languages: String {
        let locales = group.locales
        guard locales.count > 3 else { return locales.map(Self.name).formatted(.list(type: .and)) }
        return String(localized: "\(locales.count) languages")
    }

    /// "iPhone Duo", "iPhone and iPad".
    private var devices: String { group.displayTypes.map(\.shortTitle).formatted(.list(type: .and)) }

    /// The captures that wait for the answer, besides the group's own.
    private var waiting: Int {
        let own = Set(group.problems.map(\.target))
        return run.heldTargets.count { $0.screenID == group.screenID && group.displayTypes.contains($0.displayType) && !own.contains($0) }
    }

    private var othersText: String {
        if group.isDeviceWide {
            return String(localized: "Every screen on it waits, in every language; the other devices keep going.")
        }
        let others = run.plan.screens.count - 1
        if waiting > 0 {
            return waiting == 1
                ? String(localized: "1 more capture of it waits for your answer; the other screens keep going.")
                : String(localized: "\(waiting) more captures of it wait for your answer; the other screens keep going.")
        }
        return others == 1 ? String(localized: "The other screen and languages keep going.") : String(localized: "The other \(others) screens and languages keep going.")
    }

    private static func name(of code: String) -> String {
        StoreLocaleCatalog.locale(code: code)?.shortName ?? code
    }
}
