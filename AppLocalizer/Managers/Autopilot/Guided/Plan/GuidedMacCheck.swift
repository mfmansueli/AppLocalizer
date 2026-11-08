//
//  GuidedMacCheck.swift
//  AppLocalizer
//

import Foundation

/// Plan · This Mac: one row per device the run captures on, whether its
/// simulator is ready, and whether Start Autopilot has to wait. A
/// simulator to make or a platform to install keeps Start disabled, and
/// so does a helper too old to check this Mac. iPhone Duo starting closed
/// doesn't: AppLocalizer opens it when the run needs it.
struct GuidedMacCheck: Hashable, Sendable {
    /// The devices the run captures on, in the plan's order.
    let displays: [ScreenshotDisplayType]
    let state: MacSimulators.State

    /// Whether the plan shows This Mac at all: the run captures or
    /// records something.
    static func applies(to run: AutopilotRun) -> Bool {
        !run.skipsCapture && !run.plan.runDisplays.isEmpty
    }

    init(displays: [ScreenshotDisplayType], state: MacSimulators.State) {
        self.displays = displays
        self.state = state
    }

    init(run: AutopilotRun, state: MacSimulators.State) {
        self.init(displays: Self.applies(to: run) ? run.plan.runDisplays : [], state: state)
    }

    private var inventory: SimulatorInventory? {
        if case let .checked(inventory) = state { return inventory }
        return nil
    }

    func status(for display: ScreenshotDisplayType) -> SimulatorStatus? {
        inventory?.status(for: display)
    }

    /// The devices whose simulator has to be made or installed first.
    var missing: [ScreenshotDisplayType] {
        displays.filter { display in
            guard let status = status(for: display) else { return false }
            if case .ready = status { return false }
            return true
        }
    }

    /// The helper is there but too old to list the simulators.
    var helperCantCheck: Bool { state == .oldHelper }

    /// Start Autopilot waits: a simulator is missing, or the helper can't
    /// check this Mac.
    var blocksStart: Bool {
        guard !displays.isEmpty else { return false }
        return helperCantCheck || !missing.isEmpty
    }

    /// The footer's help on a disabled Start.
    static let blockedHelp = String(localized: "This Mac isn’t ready yet: see This Mac above.")

    /// The line beside "This Mac": "Ready", "1 simulator to make before
    /// Start", "Can’t check this Mac yet".
    var summary: String {
        switch state {
        case .unknown, .checking:
            return String(localized: "Checking…")
        case .noHelper:
            return String(localized: "Not checked: no helper")
        case .oldHelper:
            return String(localized: "Can’t check this Mac yet")
        case .failed:
            return String(localized: "Couldn’t check")
        case .checked:
            let missing = missing
            guard !missing.isEmpty else { return String(localized: "Ready") }
            // A simulator made in a moment, or a platform to install first.
            let onlyMakes = missing.allSatisfy { status(for: $0)?.canCapture == true }
            switch (missing.count, onlyMakes) {
            case (1, true): return String(localized: "1 simulator to make before Start")
            case (1, false): return String(localized: "1 simulator to install before Start")
            case (_, true): return String(localized: "\(missing.count) simulators to make before Start")
            case (_, false): return String(localized: "\(missing.count) simulators to set up before Start")
            }
        }
    }

    /// The summary says what holds Start: shown in bold.
    var summaryIsWarning: Bool { blocksStart }

    /// The row's text: "iPhone 17 Pro Max · iOS 27.0", "This Mac · Lumen
    /// for Mac runs here directly".
    func detail(for display: ScreenshotDisplayType, appName: String) -> String {
        if display == .mac { return String(localized: "This Mac · \(appName) for Mac runs here directly") }
        guard let status = status(for: display) else {
            return state == .checking || state == .unknown ? String(localized: "Checking…") : ""
        }
        return status.detail
    }
}
