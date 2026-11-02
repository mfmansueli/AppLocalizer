//
//  AutopilotStall.swift
//  AppLocalizer
//

import Foundation

/// Why nobody is working on a run that still has work for the assistant
/// (`AutopilotContinuation.stall`): what the sheet says above Continue.
enum AutopilotStall: Hashable, Sendable {
    /// The Claude Code AppLocalizer started ended, with its last words.
    case ended(lastWords: String?)
    /// AppLocalizer started Claude Code for the run, but none is running
    /// now: AppLocalizer was closed since.
    case notRunning
    /// The prompt was pasted, and nothing has arrived since then.
    case quiet(since: Date)
    /// Claude Code ended on the person's turn, and their step gave it work
    /// again, but AppLocalizer can't start it itself (no helper): not an
    /// error, Continue starts it or copies the prompt.
    case handedBack
}
