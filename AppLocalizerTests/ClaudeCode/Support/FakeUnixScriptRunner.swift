//
//  FakeUnixScriptRunner.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// A helper that never runs anything: `check` answers `checkLines`, and a
/// run prints `lines`, then the helper's exit line with `exitStatus`, or
/// waits until it's stopped when that's nil. Every call's arguments are
/// recorded.
final class FakeUnixScriptRunner: UnixScriptRunning, @unchecked Sendable {
    var helperExists = true
    var checkLines = FakeUnixScriptRunner.foundLines
    var lines: [String] = []
    var exitStatus: Int32? = 0
    /// What the helper wrote to stderr.
    var errorOutput = ""
    /// What `NSUserUnixTask` would report, e.g. that the script couldn't run.
    var taskError: String?
    private let calls = Mutex<[[String]]>([])

    /// Under the real home, so it shows as "~/.local/bin/claude".
    static let claudePath = ProjectFolderPath.home + "/.local/bin/claude"

    static let foundLines = [
        "helper \(ClaudeCodeHelperScript.version)",
        "claude \(claudePath)",
        "version 2.1.316 (Claude Code)",
    ]

    /// Each call's arguments, `check` included, oldest first.
    var recordedArguments: [[String]] {
        calls.withLock { $0 }
    }

    /// The arguments of the last run (not `check`).
    var lastRunArguments: [String]? {
        recordedArguments.last { $0.first == "run" }
    }

    func exists(_: URL) -> Bool {
        helperExists
    }

    func run(_: URL, arguments: [String], onLine: @escaping @Sendable (String) -> Void) async -> UnixScriptExit {
        calls.withLock { $0.append(arguments) }
        if arguments.first == "check" {
            checkLines.forEach(onLine)
            return UnixScriptExit(errorOutput: errorOutput, taskError: taskError)
        }
        lines.forEach(onLine)
        guard let exitStatus else {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(5))
            }
            onLine("\(ClaudeCodeHelperScript.exitMarker) 143")
            return UnixScriptExit(taskError: "The script exited with status 143.")
        }
        onLine("\(ClaudeCodeHelperScript.exitMarker) \(exitStatus)")
        return UnixScriptExit(errorOutput: errorOutput, taskError: taskError)
    }
}
