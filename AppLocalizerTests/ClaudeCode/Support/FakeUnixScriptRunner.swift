//
//  FakeUnixScriptRunner.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// A helper that never runs anything: `check` answers `checkLines`, and a
/// run prints `lines`, then the helper's exit line with `exitStatus`, or
/// waits until it's stopped when that's nil. With `losesExitLine`, the exit
/// line never arrives, as when an older helper couldn't write it. Every
/// call's arguments are recorded.
final class FakeUnixScriptRunner: UnixScriptRunning, @unchecked Sendable {
    var helperExists = true
    var checkLines = FakeUnixScriptRunner.foundLines
    var lines: [String] = []
    var exitStatus: Int32? = 0
    var losesExitLine = false
    /// What the helper wrote to stderr.
    var errorOutput = ""
    /// What `NSUserUnixTask` would report, e.g. that the script couldn't run.
    var taskError: String?
    /// The simulator modes' answers (`simulators`, `install-platform`,
    /// `create-simulator`): each call takes the next lines, the last ones
    /// repeat; each ends with the exit line and `statuses`' status (0).
    var answers: [String: [[String]]] = [:]
    var statuses: [String: Int32] = [:]
    /// A mode's status call by call, the last one repeating; over
    /// `statuses` when set.
    var statusSequences: [String: [Int32]] = [:]
    private let calls = Mutex<[[String]]>([])
    private let answered = Mutex<[String: Int]>([:])

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
        if let mode = arguments.first, let modeAnswers = answers[mode], !modeAnswers.isEmpty {
            let index = answered.withLock { counts in
                defer { counts[mode, default: 0] += 1 }
                return min(counts[mode, default: 0], modeAnswers.count - 1)
            }
            modeAnswers[index].forEach(onLine)
            let status = statusSequences[mode].flatMap { $0.isEmpty ? nil : $0[min(index, $0.count - 1)] } ?? statuses[mode] ?? 0
            onLine("\(ClaudeCodeHelperScript.exitMarker) \(status)")
            return UnixScriptExit(errorOutput: errorOutput, taskError: status == 0 ? nil : "The script exited with status \(status).")
        }
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
        if !losesExitLine { onLine("\(ClaudeCodeHelperScript.exitMarker) \(exitStatus)") }
        return UnixScriptExit(errorOutput: errorOutput, taskError: taskError)
    }
}
