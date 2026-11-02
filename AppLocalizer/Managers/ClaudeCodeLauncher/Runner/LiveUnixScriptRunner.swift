//
//  LiveUnixScriptRunner.swift
//  AppLocalizer
//

import Foundation

/// Runs scripts with `NSUserUnixTask`, which macOS starts outside the
/// sandbox for scripts in the app's scripts folder. Output comes back line
/// by line through a pipe, read as it arrives whatever stderr does
/// (`PipeLineReader`); stdin stays open for the whole run, and a line on it
/// is the helper's signal to stop.
struct LiveUnixScriptRunner: UnixScriptRunning {
    func exists(_ script: URL) -> Bool {
        FileManager.default.fileExists(atPath: script.path)
    }

    func run(_ script: URL, arguments: [String], onLine: @escaping @Sendable (String) -> Void) async -> UnixScriptExit {
        let task: NSUserUnixTask
        do {
            task = try NSUserUnixTask(url: script)
        } catch {
            return UnixScriptExit(taskError: error.localizedDescription)
        }
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        task.standardInput = input.fileHandleForReading
        task.standardOutput = output.fileHandleForWriting
        task.standardError = errors.fileHandleForWriting
        let stopHandle = input.fileHandleForWriting

        // Both pipes are read from the start, each on its own, so a full one
        // never makes the script wait.
        let printedLines = PipeLineReader.lines(of: output.fileHandleForReading)
        let errorLines = PipeLineReader.lines(of: errors.fileHandleForReading)
        async let printed: Void = Self.forEach(printedLines, onLine)
        async let errorText = Self.text(of: errorLines)
        let taskError: String? = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
                task.execute(withArguments: arguments) { error in
                    continuation.resume(returning: error?.localizedDescription)
                }
            }
        } onCancel: {
            try? stopHandle.write(contentsOf: Data("stop\n".utf8))
        }
        // This process's own write ends: closing them lets both readers reach
        // the end once the script's copies are gone.
        try? output.fileHandleForWriting.close()
        try? errors.fileHandleForWriting.close()
        try? stopHandle.close()
        await printed
        let stderr = await errorText
        return UnixScriptExit(errorOutput: String(stderr.suffix(4000)), taskError: taskError)
    }

    /// Stops early when the run is cancelled (Stop); the pipe is still
    /// drained.
    private static func forEach(_ lines: AsyncStream<String>, _ onLine: @Sendable (String) -> Void) async {
        for await line in lines {
            onLine(line)
        }
    }

    /// stderr's last lines: only the end is shown.
    private static func text(of lines: AsyncStream<String>) async -> String {
        var collected: [String] = []
        for await line in lines {
            collected.append(line)
            if collected.count > 400 { collected.removeFirst(200) }
        }
        return collected.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
