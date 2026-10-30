//
//  ProjectFolderPicker.swift
//  AppLocalizer
//

import AppKit

/// Choose…: the app's project folder, which the sandbox then lets
/// AppLocalizer read.
@MainActor
enum ProjectFolderPicker {
    static func choose() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Choose")
        panel.message = String(localized: "Choose the app’s project folder. AppLocalizer reads its commit messages and CHANGELOG.md, never its code.")
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    /// A security-scoped bookmark, so the folder can be read after a
    /// relaunch; nil where the sandbox doesn't allow one.
    static func bookmark(for url: URL) -> Data? {
        try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    }
}
