//
//  ClaudeCodeInstallation.swift
//  AppLocalizer
//

import Foundation

/// The Claude Code the helper found on this Mac, e.g. version "2.1.316" at
/// `~/.local/bin/claude`.
struct ClaudeCodeInstallation: Hashable, Codable, Sendable {
    /// Where `claude` is, as the helper printed it.
    var path: String
    /// "2.1.316", or empty when it didn't say.
    var version: String
    /// The saved helper's own version (`ClaudeCodeHelperScript.version`).
    var helperVersion: Int

    /// "2.1.316 (Claude Code)" → "2.1.316".
    static func shortVersion(_ text: String) -> String {
        text.split(separator: " ").first.map(String.init) ?? text
    }

    /// "Claude Code 2.1.316", or "Claude Code".
    var title: String {
        version.isEmpty ? "Claude Code" : "Claude Code \(version)"
    }

    /// The path with the home folder as "~".
    func displayPath(home: String = ProjectFolderPath.home) -> String {
        ProjectFolderPath.abbreviated(path, home: home)
    }
}
