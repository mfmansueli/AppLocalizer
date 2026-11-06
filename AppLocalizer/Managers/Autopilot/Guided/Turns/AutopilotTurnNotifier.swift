//
//  AutopilotTurnNotifier.swift
//  AppLocalizer
//

import Foundation
import UserNotifications

/// Posts "Autopilot needs you" when a guided run reaches one of the
/// person's stops, so they can walk away while it works. Asks for
/// permission when a guided run starts.
@MainActor
final class AutopilotTurnNotifier {
    static let shared = AutopilotTurnNotifier()

    /// Nil in tests and DEBUG scenes: nothing is posted.
    private let center: UNUserNotificationCenter?

    init(center: UNUserNotificationCenter? = Bundle.main.bundleIdentifier == nil ? nil : .current()) {
        self.center = center
    }

    /// Asks once; macOS remembers the answer.
    func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// The notification for `turn` in `run`, replacing the app's last one.
    func post(_ turn: AutopilotTurn, run: AutopilotRun, appName: String) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = turn.title
        content.body = turn.body(appName: appName, startedAt: run.startedAt)
        content.sound = .default
        content.threadIdentifier = "autopilot"
        let request = UNNotificationRequest(identifier: "autopilot.\(run.appID)", content: content, trigger: nil)
        center.add(request)
    }

    /// The name a run's notification shows: its App Store name in the
    /// primary language, once read.
    static func appName(of run: AutopilotRun) -> String {
        run.storeNames?[run.plan.primaryLocale] ?? String(localized: "Screenshot Autopilot")
    }
}
