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
    /// Whether the sample data is in each capture's language; nil (runs
    /// from before) counts as yes. Use `sampleDataInEachLanguage`.
    var localizesSampleData: Bool?
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

    /// Entries, names and places in the capture's language: a Japanese
    /// screen with English sample entries looks unfinished.
    var sampleDataInEachLanguage: Bool {
        get { localizesSampleData ?? true }
        set { localizesSampleData = newValue }
    }

    /// How the assistant gets sample data in each language.
    static let sampleDataLanguageNote = """
    Use sample data in each capture's language: the entries, names, places and other content the app shows should read naturally \
    there, not in the primary language. Seed it after launching with the locale's launchArguments, so the seed can read \
    Locale.preferredLanguages. If the sample-data switch makes only one language's content, add the plan's other languages to the \
    app's debug or UI-test sample data (never to code that ships) and say so in report_capture's notes.
    """

    /// The status bar override, as `get_capture_plan` gives it: Apple's
    /// 9:41, full battery, full bars on Wi-Fi and no carrier name. The
    /// battery is discharging at 100%: "charged" draws it green with a
    /// charging bolt (Bruma's captures), not the plain full battery of
    /// Apple's own screenshots.
    static let statusBarCommand = """
    xcrun simctl status_bar booted override --time 9:41 --batteryState discharging --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --dataNetwork wifi --wifiBars 3 --operatorName ''
    """

    /// The commands say `booted`, which reaches one simulator when several
    /// run: Bruma's run set the iPhone up and captured iPhone Duo with the
    /// status bar an earlier run left (a charging battery).
    static let eachSimulatorNote = """
    Run these on every simulator the plan captures, with its id in place of booted (booted reaches only one when several \
    are running), and check that device's first capture: 9:41, a full battery without a charging bolt, light appearance.
    """

    /// Grants every privacy permission simctl can grant to the app.
    static func permissionsCommand(bundleID: String) -> String {
        "xcrun simctl privacy booted grant all \(bundleID)"
    }

    /// What the assistant does about alerts simctl can't prevent. simctl
    /// can't grant notifications ("Operation not permitted") or tap a
    /// prompt, and a prompt left from an earlier launch stays until it's
    /// answered (Bruma's first capture had one over its debug scene).
    static let alertsNote = """
    Before capturing, launch the app once in each simulator with the captures' own launch arguments and answer any \
    prompt simctl can't grant (notifications: Don't Allow; tracking: Ask App Not to Track), so no alert, banner or \
    sheet is ever in a capture. simctl can neither grant notifications nor tap a prompt, and a prompt left from an \
    earlier launch stays up until it's answered: answer it with a UI test run on that simulator's id with \
    -parallel-testing-enabled NO (one the project has, or a small one in its UI test target that taps \
    XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]), never by erasing the simulator.
    """
}
