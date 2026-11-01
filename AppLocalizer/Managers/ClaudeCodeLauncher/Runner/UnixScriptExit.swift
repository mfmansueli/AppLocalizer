//
//  UnixScriptExit.swift
//  AppLocalizer
//

import Foundation

/// How a script run ended: what it wrote to stderr, and the error
/// `NSUserUnixTask` reported, if any (the script couldn't start, or it ended
/// with a non-zero status). The helper prints its own status on a line of
/// its own (`ClaudeCodeHelperScript.exitMarker`), which is what counts.
struct UnixScriptExit: Hashable, Sendable {
    /// The last part of stderr, trimmed.
    var errorOutput: String = ""
    var taskError: String?

    /// stderr's last line, for a one-line message.
    var lastErrorLine: String? {
        errorOutput.split(whereSeparator: \.isNewline).last.map { String($0).trimmingCharacters(in: .whitespaces) }
    }
}
