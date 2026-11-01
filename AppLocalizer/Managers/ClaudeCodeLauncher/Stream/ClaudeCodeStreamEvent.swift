//
//  ClaudeCodeStreamEvent.swift
//  AppLocalizer
//

import Foundation

/// What a line of `claude -p --output-format stream-json` says, as far as
/// AppLocalizer shows it: the session starting, Claude's words, each tool it
/// used, a tool that failed, and the result. Lines it doesn't show (hooks,
/// rate limits, thinking) parse to nil (`ClaudeCodeStreamParser`).
enum ClaudeCodeStreamEvent: Hashable, Sendable {
    /// `system/init`.
    case started(sessionID: String, model: String?, version: String?, failedServers: [String])
    /// An assistant message's text.
    case said(String)
    /// An assistant message's tool call.
    case usedTool(ClaudeCodeToolUse)
    /// A tool result marked as an error.
    case toolFailed(toolUseID: String, message: String)
    /// `result`, the run's last line.
    case finished(ClaudeCodeResult)
}
