//
//  AutopilotSimulatorSetup.swift
//  AppLocalizer
//

import Foundation

/// How the assistant prepares the simulators before capturing, with
/// Xcode's own tools.
struct AutopilotSimulatorSetup: Codable, Hashable, Sendable {
    /// 9:41, full battery and signal (`xcrun simctl status_bar … override`).
    var overridesStatusBar = true
    /// The app's sample-data switch, e.g. "Settings → Debug → Add Sample
    /// Week"; empty when the assistant should find it.
    var usesSampleData = true
    var sampleDataSteps = ""
    /// Light appearance and no notifications.
    var lightAppearance = true
    /// Commands added by fixes, e.g. `xcrun simctl privacy booted grant
    /// photos <bundle ID>`, run before capturing.
    var extraCommands: [String] = []

    /// The status bar override, as `get_capture_plan` gives it.
    static let statusBarCommand = "xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3"
}
