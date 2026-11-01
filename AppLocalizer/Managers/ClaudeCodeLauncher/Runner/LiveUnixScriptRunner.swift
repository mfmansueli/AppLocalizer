//
//  LiveUnixScriptRunner.swift
//  AppLocalizer
//

import Foundation

/// Runs scripts with `NSUserUnixTask`, which macOS starts outside the
/// sandbox for scripts in the app's scripts folder. Output comes back line
/// by line through a pipe; stdin stays open for the whole run, and a line
/// on it is the helper's signal to stop.
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

        async let printed: Void = Self.forEachLine(of: output.fileHandleForReading, onLine)
        async let errorText = Self.text(of: errors.fileHandleForReading)
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

    private static func forEachLine(of handle: FileHandle, _ onLine: @Sendable (String) -> Void) async {
        do {
            for try await line in handle.bytes.lines {
                onLine(line)
            }
        } catch {
            // The pipe closed early; whatever arrived was passed on.
        }
    }

    private static func text(of handle: FileHandle) async -> String {
        var lines: [String] = []
        do {
            for try await line in handle.bytes.lines {
                lines.append(line)
            }
        } catch {
            // As above.
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
