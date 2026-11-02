//
//  SimulatorHelperAnswer.swift
//  AppLocalizer
//

import Foundation

/// What the helper (`ClaudeCodeHelperScript`) answered to one of its
/// simulator commands: the lines it printed, the status on its own exit
/// line, and how the script ended.
struct SimulatorHelperAnswer: Sendable {
    var lines: [String] = []
    /// The helper's own exit line's; nil when it didn't print one.
    var status: Int32?
    var exit = UnixScriptExit()

    var succeeded: Bool { status == 0 }

    /// A helper from before the command: it printed its usage line and no
    /// exit line.
    var isFromOlderHelper: Bool { status == nil && exit.errorOutput.contains("Usage:") }

    /// Why it didn't work, in a line.
    var failure: String? {
        guard !succeeded else { return nil }
        return exit.lastErrorLine ?? exit.taskError ?? lines.last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
