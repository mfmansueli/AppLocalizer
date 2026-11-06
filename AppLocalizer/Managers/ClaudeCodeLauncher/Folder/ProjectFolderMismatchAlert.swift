//
//  ProjectFolderMismatchAlert.swift
//  AppLocalizer
//

import AppKit

/// Asked when the chosen folder's projects build other apps: choose
/// another folder (the default), or use this one anyway.
@MainActor
enum ProjectFolderMismatchAlert {
    /// True to use the folder anyway.
    static func usesAnyway(appName: String, bundleID: String, found: [String]) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "This folder doesn’t build \(appName)")
        let builds = found.prefix(3).formatted(.list(type: .and))
        alert.informativeText = String(localized: """
        Its Xcode project builds \(builds), not \(bundleID). Claude Code would capture and read the wrong app.
        """)
        alert.addButton(withTitle: String(localized: "Choose Another Folder…"))
        alert.addButton(withTitle: String(localized: "Use This Folder"))
        return alert.runModal() == .alertSecondButtonReturn
    }
}
