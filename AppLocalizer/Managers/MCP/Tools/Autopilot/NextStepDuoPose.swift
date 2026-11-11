//
//  NextStepDuoPose.swift
//  AppLocalizer
//

import Foundation

/// `next_step` folds iPhone Duo before it gives the closed screens, which
/// are captured on its cover display. Alba's 1.1.0 run started with the Duo
/// left open by the run before; the watcher that closes it lives in the
/// Making step and didn't look in time, the assistant read that the Duo
/// starts folded, and all four cover screenshots came back black. Asked
/// here, it's folded whoever runs the tests and whether the sheet is open.
@MainActor
enum NextStepDuoPose {
    /// A restart takes a few seconds; a busy Mac boots it in about 30.
    static let limit: Duration = .seconds(90)

    /// Folds the Duo when the run's closed Duo screens are next; what the
    /// assistant should know about it then, nil when they aren't. A fold
    /// tries the Duo's device-wide problems again, as the watcher does.
    static func prepare(app: StoreApp, center: AutopilotCenter, in context: MCPToolContext) async -> String? {
        guard let run = center.run(for: app.id), run.stage == .capture, run.duoPoseWanted == .closed,
              let simulators = context.simulators, simulators.hasHelper
        else { return nil }
        let appID = app.id
        var folded = false
        let state = await simulators.duo.makeClosed(within: limit) { event in
            // Still open after two restarts isn't "captured next".
            guard event != .opened else { return }
            center.update(appID) { $0.appendLog(event.logText, kind: .event, at: center.now()) }
            if event == .closed { folded = true }
        }
        guard state == .closedForScreens else {
            return """
            iPhone Duo isn't folded, and AppLocalizer can't fold it by itself now: \(state.summary) Capture the other \
            devices first; if only iPhone Duo's closed targets are left, report it once with report_capture_problem \
            (displayType iphone_duo, affectsDevice true).
            """
        }
        if folded, let run = center.run(for: appID) {
            let ids = run.openProblems.filter { $0.isDeviceWide && $0.target.displayType == .iPhoneDuo }.map(\.id)
            if !ids.isEmpty {
                let autopilot = MCPAutopilotSession.context(app: app, run: run, in: context)
                await center.resolveProblems(appID: appID, problemIDs: ids, with: .retryWithFix, context: autopilot)
            }
        }
        return """
        iPhone Duo is folded: capture its closed targets now, on the 1398 × 2034 cover display. Don't open, restart \
        or shut it down yourself.
        """
    }
}
