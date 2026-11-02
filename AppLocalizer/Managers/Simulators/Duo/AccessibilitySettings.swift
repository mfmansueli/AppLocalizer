//
//  AccessibilitySettings.swift
//  AppLocalizer
//

import AppKit

/// System Settings' Privacy & Security › Accessibility, where the person
/// allows AppLocalizer once so its helper can press Open on iPhone Duo in
/// Device Hub (`DuoWatcher`). The helper's first try has macOS ask and list
/// AppLocalizer there.
enum AccessibilitySettings {
    static let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

    @MainActor
    static func open() {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}
