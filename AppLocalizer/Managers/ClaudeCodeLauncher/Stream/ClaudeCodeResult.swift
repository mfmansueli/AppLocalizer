//
//  ClaudeCodeResult.swift
//  AppLocalizer
//

import Foundation

/// The `result` line that ends a print run: whether it succeeded, Claude's
/// last words, and the calls it wasn't allowed to make.
struct ClaudeCodeResult: Hashable, Sendable {
    /// A tool call refused because the run's permissions don't allow it.
    struct Denial: Hashable, Sendable {
        var toolName: String
        /// "swift package resolve", "Edit Info.plist".
        var summary: String
    }

    var isError: Bool
    /// The last assistant message, or the error.
    var text: String
    var sessionID: String?
    /// "success", "error_max_turns", "error_during_execution".
    var subtype: String?
    var turns: Int?
    var duration: Duration?
    var apiErrorStatus: Int?
    var denials: [Denial] = []

    /// Claude Code isn't logged in, or its key was refused.
    var isLoginProblem: Bool {
        guard isError else { return false }
        if apiErrorStatus == 401 { return true }
        let text = text.lowercased()
        return text.contains("/login") || text.contains("invalid api key") || text.contains("not logged in")
            || text.contains("oauth token")
    }
}
