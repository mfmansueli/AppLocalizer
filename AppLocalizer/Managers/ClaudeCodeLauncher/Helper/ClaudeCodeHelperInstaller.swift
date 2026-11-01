//
//  ClaudeCodeHelperInstaller.swift
//  AppLocalizer
//

import AppKit
import UniformTypeIdentifiers

/// Install Helper…: a Save panel opened on the app's scripts folder with
/// the file name filled in, so the person only clicks Save. The sandbox
/// lets AppLocalizer write the file the person chose there, but never that
/// folder on its own.
@MainActor
enum ClaudeCodeHelperInstaller {
    enum Problem: LocalizedError, Equatable {
        /// Saved somewhere else, where macOS won't run it for AppLocalizer.
        case wrongFolder(String)
        case couldNotWrite(String)

        var errorDescription: String? {
            switch self {
            case let .wrongFolder(folder):
                String(localized: "The helper only works in \(folder). Save it there, without changing the folder.")
            case let .couldNotWrite(message):
                String(localized: "Couldn’t save the helper: \(message)")
            }
        }
    }

    /// The folder macOS runs AppLocalizer's scripts from,
    /// `~/Library/Application Scripts/<bundle ID>/`.
    static var scriptsDirectory: URL? {
        try? FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    /// Where the helper goes.
    static var helperURL: URL? {
        scriptsDirectory?.appending(path: ClaudeCodeHelperScript.fileName)
    }

    /// Shows the Save panel and writes the helper. Returns false when the
    /// person cancelled.
    @discardableResult
    static func install() throws(Problem) -> Bool {
        guard let directory = scriptsDirectory else { throw .couldNotWrite(String(localized: "There’s no scripts folder for AppLocalizer.")) }
        let panel = NSSavePanel()
        panel.directoryURL = directory
        panel.nameFieldStringValue = ClaudeCodeHelperScript.fileName
        panel.canCreateDirectories = false
        panel.isExtensionHidden = false
        panel.allowedContentTypes = [UTType(filenameExtension: "zsh") ?? .shellScript]
        panel.prompt = String(localized: "Save Helper")
        panel.message = String(localized: """
        Save the helper here, without changing the folder. macOS runs it for AppLocalizer, outside its sandbox, \
        and only when you ask AppLocalizer to start Claude Code.
        """)
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        try write(to: url, scriptsDirectory: directory)
        return true
    }

    /// Writes the helper to `url`, executable, after checking it's in
    /// `scriptsDirectory`.
    static func write(to url: URL, scriptsDirectory directory: URL) throws(Problem) {
        guard url.deletingLastPathComponent().standardizedFileURL.path == directory.standardizedFileURL.path else {
            throw .wrongFolder(ProjectFolderPath.abbreviated(directory.path))
        }
        do {
            try Data(ClaudeCodeHelperScript.contents.utf8).write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        } catch {
            throw .couldNotWrite(error.localizedDescription)
        }
    }

    /// Show in Finder: the scripts folder with the helper selected, where
    /// the person can delete it.
    static func reveal() {
        guard let url = helperURL else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else if let directory = scriptsDirectory {
            NSWorkspace.shared.open(directory)
        }
    }
}
