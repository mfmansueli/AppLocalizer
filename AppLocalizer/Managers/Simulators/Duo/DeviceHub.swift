//
//  DeviceHub.swift
//  AppLocalizer
//

import AppKit

/// Xcode's Device Hub, where the person opens iPhone Duo. Its simulator
/// starts closed, with apps on its 1398 × 2034 cover display and the inner
/// display black, and no command opens it: `simctl`, `devicectl` and XCTest
/// only read the hinge. The Duo's window in Device Hub has its poses
/// (closed, open, tent) and the hinge.
enum DeviceHub {
    static let bundleIdentifier = "com.apple.dt.Devices"

    /// What the person does, for the sheet: open it.
    static let openingSteps = String(localized: """
    In Device Hub, select iPhone Duo and choose Open in its window’s poses, or drag its hinge all the way open. Keep it \
    running: starting it again closes it.
    """)

    /// What the person does when its SpringBoard is stuck (a spinner on the
    /// inner display) and AppLocalizer can't restart it (`DuoWatcher`).
    static let restartSteps = String(localized: """
    If its inner display shows only a spinner, shut it down there, start it, wait for the Home Screen and open it.
    """)

    /// Where it is, or nil when this Mac's Xcode has none.
    @MainActor
    static var url: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    @MainActor
    static func open() {
        guard let url else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
