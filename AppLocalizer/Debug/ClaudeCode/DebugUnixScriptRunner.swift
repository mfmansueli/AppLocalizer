//
//  DebugUnixScriptRunner.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// DEBUG scenes' pretend helper: `check` answers with canned lines, and a
/// run prints a canned Claude Code stream, then either ends with the
/// helper's status or keeps going until it's stopped. The simulator modes
/// answer for a pretend Mac (`DebugSimulators`). Nothing runs.
struct DebugUnixScriptRunner: UnixScriptRunning {
    /// One line of a pretend run, after `delay`.
    struct Line: Sendable {
        var delay: Duration
        var text: String
    }

    /// What one run prints, and how it ends.
    struct Script: Sendable {
        var lines: [Line] = []
        /// Ends with this status after the lines; nil keeps it going until
        /// Stop.
        var exitStatus: Int32? = 0
    }

    var helperExists = true
    var checkLines = DebugUnixScriptRunner.foundLines
    var script = Script()
    /// Scripts for runs whose session name contains the key, e.g.
    /// "Screenshot Autopilot", so one scene can show several runs.
    var scripts: [String: Script] = [:]

    static let foundLines = [
        "helper \(ClaudeCodeHelperScript.version)",
        "claude \(ProjectFolderPath.home)/.nvm/versions/node/v22.23.2/bin/claude",
        "version 2.1.316 (Claude Code)",
    ]

    func exists(_: URL) -> Bool {
        helperExists
    }

    /// Answers only about the pretend Mac's simulators (`DebugSimulators`).
    static let simulators = DebugUnixScriptRunner()

    func run(_: URL, arguments: [String], onLine: @escaping @Sendable (String) -> Void) async -> UnixScriptExit {
        if let mode = arguments.first, DebugSimulators.modes.contains(mode) {
            return await DebugSimulators.answer(arguments, onLine: onLine)
        }
        if arguments.first == "check" {
            checkLines.forEach(onLine)
            return UnixScriptExit()
        }
        let chosen = script(for: arguments)
        for line in chosen.lines {
            guard await wait(line.delay) else { return stopped(onLine) }
            onLine(line.text)
        }
        guard let exitStatus = chosen.exitStatus else {
            while await wait(.seconds(3600)) {}
            return stopped(onLine)
        }
        onLine("\(ClaudeCodeHelperScript.exitMarker) \(exitStatus)")
        return exitStatus == 0 ? UnixScriptExit() : UnixScriptExit(taskError: "The script exited with status \(exitStatus).")
    }

    /// The script for the run's `--name`.
    private func script(for arguments: [String]) -> Script {
        guard let index = arguments.firstIndex(of: "--name"), arguments.indices.contains(index + 1) else { return script }
        let name = arguments[index + 1]
        return scripts.first { name.contains($0.key) }?.value ?? script
    }

    /// Whether it waited without being stopped.
    private func wait(_ delay: Duration) async -> Bool {
        guard delay > .zero else { return !Task.isCancelled }
        do {
            try await Task.sleep(for: delay)
            return true
        } catch {
            return false
        }
    }

    /// Stop: the helper's SIGTERM status.
    private func stopped(_ onLine: @Sendable (String) -> Void) -> UnixScriptExit {
        onLine("\(ClaudeCodeHelperScript.exitMarker) 143")
        return UnixScriptExit(taskError: "The script exited with status 143.")
    }
}
#endif
