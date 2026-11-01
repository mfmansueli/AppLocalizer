//
//  ClaudeCodeRunFailure.swift
//  AppLocalizer
//

import Foundation

/// Why a run AppLocalizer started didn't work, said in words with what to
/// do next.
enum ClaudeCodeRunFailure: Hashable, Sendable {
    /// The helper was deleted, or is older than this AppLocalizer.
    case helperMissing
    case claudeMissing
    case folderMissing(String)
    /// Claude Code isn't logged in, with what it said.
    case notLoggedIn(String)
    /// AppLocalizer's server couldn't start, so Claude Code had nothing to
    /// connect to.
    case serverUnavailable(String)
    /// AppLocalizer's server didn't connect inside Claude Code.
    case serverNotConnected
    /// macOS couldn't run the helper.
    case couldNotStart(String)
    /// Claude Code ended with an error, with what it said.
    case claudeError(String)
    /// The helper ended without a result, with its status and last error.
    /// No status: Claude Code started, but its end never reached
    /// AppLocalizer.
    case exited(status: Int32?, message: String?)

    /// The helper's exit status for each problem it reports itself.
    static let claudeMissingStatus: Int32 = 127
    static let folderMissingStatus: Int32 = 66

    /// "Claude Code needs you to log in".
    var title: String {
        switch self {
        case .helperMissing: String(localized: "The helper isn’t installed")
        case .claudeMissing: String(localized: "Claude Code isn’t installed")
        case .folderMissing: String(localized: "The project folder isn’t there")
        case .notLoggedIn: String(localized: "Claude Code needs you to log in")
        case .serverUnavailable: String(localized: "AppLocalizer’s server couldn’t start")
        case .serverNotConnected: String(localized: "Claude Code couldn’t reach AppLocalizer")
        case .couldNotStart: String(localized: "Claude Code couldn’t start")
        case .claudeError: String(localized: "Claude Code stopped with an error")
        case .exited: String(localized: "Claude Code ended early")
        }
    }

    /// What happened and what to do.
    var detail: String {
        switch self {
        case .helperMissing:
            String(localized: "Install the helper again in Settings → AI Assistants, or copy the prompt instead.")
        case .claudeMissing:
            String(localized: "The helper found no claude command on this Mac. Install Claude Code, then try again.")
        case let .folderMissing(folder):
            String(localized: "\(ProjectFolderPath.abbreviated(folder)) was moved or deleted. Choose the project folder again.")
        case let .notLoggedIn(message):
            String(localized: "It said: “\(message)”. Open it in Terminal, log in with /login, then try again.")
        case let .serverUnavailable(message):
            String(localized: "\(message) Check Settings → AI Assistants, then try again.")
        case .serverNotConnected:
            String(localized: "Its connection to AppLocalizer failed. Make sure AppLocalizer’s server is on, then try again.")
        case let .couldNotStart(message):
            String(localized: "macOS said: \(message)")
        case let .claudeError(message):
            message.isEmpty ? String(localized: "Show Output has what it did before it stopped.") : message
        case let .exited(status?, message):
            message.map { String(localized: "It said: \($0) (status \(status)).") }
                ?? String(localized: "It ended with status \(status) before it finished.")
        case let .exited(nil, message):
            message.map { String(localized: "It started, but its result didn’t reach AppLocalizer. It said: \($0)") }
                ?? String(localized: "It started, but its result didn’t reach AppLocalizer. Show Output has what it did.")
        }
    }

    /// Open in Terminal can get past it: logging in, or a closer look.
    var suggestsTerminal: Bool {
        switch self {
        case .notLoggedIn, .claudeError, .exited, .serverNotConnected: true
        case .helperMissing, .claudeMissing, .folderMissing, .serverUnavailable, .couldNotStart: false
        }
    }

    /// Choose Folder… is the way out.
    var needsFolder: Bool {
        if case .folderMissing = self { return true }
        return false
    }

    /// The failure for a run that ended without a successful result.
    /// `started`: Claude Code's first event arrived, so the helper ran even
    /// when its status never did.
    static func classify(status: Int32?, result: ClaudeCodeResult?, exit: UnixScriptExit, folder: String, started: Bool = false) -> ClaudeCodeRunFailure {
        if let result, result.isError {
            if result.isLoginProblem { return .notLoggedIn(result.text) }
            return .claudeError(result.text)
        }
        switch status {
        case claudeMissingStatus: return .claudeMissing
        case folderMissingStatus: return .folderMissing(folder)
        case let status?: return .exited(status: status, message: exit.lastErrorLine)
        case nil where started: return .exited(status: nil, message: exit.lastErrorLine)
        case nil: return .couldNotStart(exit.taskError ?? exit.lastErrorLine ?? String(localized: "The helper didn’t run."))
        }
    }
}
