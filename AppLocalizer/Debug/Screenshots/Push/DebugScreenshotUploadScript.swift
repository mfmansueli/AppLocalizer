//
//  DebugScreenshotUploadScript.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// How a DEBUG scene's simulated uploads behave: how long each request
/// takes, images that stop at a step (to show a push in progress), and
/// images that fail once, so Retry Failed succeeds. Images are named by
/// the start of their file name, e.g. `zh-Hans_iPhone_1_`.
struct DebugScreenshotUploadScript: Sendable {
    enum Step: Sendable {
        case reserve
        /// Uploading stops after this many parts.
        case upload(afterParts: Int)
        case commit
    }

    var delay: Duration = .milliseconds(40)
    var holds: [String: Step] = [:]
    /// Part 2 of 3 times out, once.
    var timeouts: Set<String> = []
    /// Apple reports `IMAGE_TOOL_FAILURE`, once.
    var processingFailures: Set<String> = []
    /// Requests already used this hour.
    var usedThisHour = 372

    static func matching(_ fileName: String, in names: some Sequence<String>) -> String? {
        names.first { fileName.hasPrefix($0) }
    }
}
#endif
