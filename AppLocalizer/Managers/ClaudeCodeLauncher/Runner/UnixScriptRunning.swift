//
//  UnixScriptRunning.swift
//  AppLocalizer
//

import Foundation

/// Runs a script from AppLocalizer's scripts folder outside the sandbox, as
/// `NSUserUnixTask` does (`LiveUnixScriptRunner`); tests and DEBUG scenes
/// answer with canned lines instead.
protocol UnixScriptRunning: Sendable {
    /// Whether `script` is in place to run.
    func exists(_ script: URL) -> Bool

    /// Runs `script` with `arguments` and calls `onLine` with each line it
    /// prints, until it ends. Cancelling the task asks the script to stop
    /// (a line on its stdin); it still returns once the script has ended.
    func run(_ script: URL, arguments: [String], onLine: @escaping @Sendable (String) -> Void) async -> UnixScriptExit
}
