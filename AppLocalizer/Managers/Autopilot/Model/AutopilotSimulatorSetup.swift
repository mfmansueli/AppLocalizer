//
//  AutopilotSimulatorSetup.swift
//  AppLocalizer
//

import Foundation

/// How the assistant prepares the simulators before capturing, with
/// Xcode's own tools.
struct AutopilotSimulatorSetup: Codable, Hashable, Sendable {
    /// 9:41, full battery and signal, no carrier name (`xcrun simctl
    /// status_bar … override`).
    var overridesStatusBar = true
    /// The app's sample-data switch, e.g. "Settings → Debug → Add Sample
    /// Week"; empty when the assistant should find it.
    var usesSampleData = true
    var sampleDataSteps = ""
    /// Light appearance and no notifications: notification prompts are
    /// answered before capturing.
    var lightAppearance = true
    /// Whether the app's permissions are granted before capturing; nil
    /// (runs from before) counts as yes. Use `grantsPermissions`.
    var grantsPermissionsUpFront: Bool?
    /// Commands added by fixes, e.g. `xcrun simctl privacy booted grant
    /// photos <bundle ID>`, run before capturing.
    var extraCommands: [String] = []

    /// Photos, location, contacts and the rest are granted up front
    /// (`xcrun simctl privacy … grant all`), so no permission alert lands
    /// in a capture.
    var grantsPermissions: Bool {
        get { grantsPermissionsUpFront ?? true }
        set { grantsPermissionsUpFront = newValue }
    }

    /// The status bar override, as `get_capture_plan` gives it: Apple's
    /// 9:41, full battery, full bars on Wi-Fi and no carrier name.
    static let statusBarCommand = """
    xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --dataNetwork wifi --wifiBars 3 --operatorName ''
    """

    /// Grants every privacy permission simctl can grant to the app.
    static func permissionsCommand(bundleID: String) -> String {
        "xcrun simctl privacy booted grant all \(bundleID)"
    }

    /// What the assistant does about alerts simctl can't prevent.
    static let alertsNote = """
    Before capturing, launch the app once in each simulator and answer any prompt simctl can't grant (notifications: \
    Don't Allow; tracking: Ask App Not to Track), so no alert, banner or sheet is ever in a capture.
    """
}
