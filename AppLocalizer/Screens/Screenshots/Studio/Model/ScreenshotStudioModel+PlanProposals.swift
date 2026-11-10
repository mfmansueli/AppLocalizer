//
//  ScreenshotStudioModel+PlanProposals.swift
//  AppLocalizer
//

import Foundation

/// What the assistant sent for the next plan outside a run (screens to
/// add, changes to accept or reject) and the commands and notes fixes
/// added, which the person can remove at Plan.
extension ScreenshotStudioModel {
    var planProposals: AutopilotPlanProposals {
        autopilot?.planProposals(for: app.id) ?? AutopilotPlanProposals()
    }

    /// The screens sent for `display`'s (iPhone for the set's).
    func queuedScreens(on display: ScreenshotDisplayType) -> [AutopilotScreenSuggestions] {
        planProposals.screens(on: display)
    }

    func acceptPlanChange(_ id: String) {
        autopilot?.acceptPlanChange(id, appID: app.id)
    }

    func rejectPlanChange(_ id: String) {
        autopilot?.rejectPlanChange(id, appID: app.id)
    }

    func closeQueuedScreens(_ id: String) {
        autopilot?.closeQueuedScreens(id, appID: app.id)
    }

    /// Remove on a command a fix added: the next runs don't run it.
    func removeFixCommand(_ command: String) {
        updatePlan { $0.simulator.extraCommands.removeAll { $0 == command } }
    }

    /// Remove on a note a fix left.
    func removeFixNote(_ note: String) {
        updatePlan { $0.simulator.fixNotes.removeAll { $0 == note } }
    }

    /// "For the next run: 1 plan change and 2 suggested screens from
    /// Claude Code."; nil when nothing waits.
    var planProposalsLine: String? {
        let proposals = planProposals
        guard proposals.isWaiting else { return nil }
        let clients = proposals.changes.map(\.client) + proposals.screens.filter { !$0.open.isEmpty }.map(\.client)
        let client = clients.first ?? String(localized: "the assistant")
        let changes = proposals.changes.count
        let screens = proposals.openScreenCount
        let changesText = changes == 1 ? String(localized: "1 plan change") : String(localized: "\(changes) plan changes")
        let screensText = screens == 1 ? String(localized: "1 suggested screen") : String(localized: "\(screens) suggested screens")
        let what = switch (changes > 0, screens > 0) {
        case (true, true): String(localized: "\(changesText) and \(screensText)")
        case (true, false): changesText
        default: screensText
        }
        return String(localized: "For the next run: \(what) from \(client).")
    }
}
