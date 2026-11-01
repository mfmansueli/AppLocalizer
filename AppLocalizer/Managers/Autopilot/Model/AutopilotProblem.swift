//
//  AutopilotProblem.swift
//  AppLocalizer
//

import Foundation

/// A screen the assistant couldn't reach. The rest keeps going; the person
/// takes the proposed fix, reuses the primary language's capture or
/// uploads one by hand. When the fix is a change to the project (a test, a
/// scheme, sample data), or a command was refused, retrying doesn't add it
/// to the plan's commands.
struct AutopilotProblem: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var target: AutopilotCaptureTarget
    /// "The photo picker asked for access and covered the entry."
    var what: String
    /// A command or step, e.g. `xcrun simctl privacy booted grant photos …`.
    var proposedFix: String?
    /// The command the session wasn't allowed to run, e.g.
    /// `TEST_RUNNER_SCREENSHOTS=1 xcodebuild test …` in AppLocalizer's own
    /// Claude Code, which may only run commands that start with xcodebuild,
    /// xcrun simctl and the like.
    var refusedCommand: String?
    /// The assistant said the fix changes the project rather than being a
    /// command; nil when it didn't say (see `needsProjectChange`).
    var changesProject: Bool?
    var resolution: AutopilotProblemResolution?
    var reportedAt: Date

    var isOpen: Bool { resolution == nil }

    var wasRefused: Bool { refusedCommand?.isEmpty == false }

    /// The project has to change before a retry can work: the assistant
    /// said so, a command was refused, or the fix doesn't read as a command
    /// ("In ScreenshotUITests.swift:78 tap … instead of …").
    var needsProjectChange: Bool {
        if wasRefused { return true }
        if let changesProject { return changesProject }
        guard let fix = proposedFix?.trimmingCharacters(in: .whitespacesAndNewlines), !fix.isEmpty else { return false }
        return !Self.looksLikeCommand(fix)
    }

    /// A one-line command a simulator setup can run, e.g. `xcrun simctl
    /// privacy booted grant photos …`.
    static func looksLikeCommand(_ text: String) -> Bool {
        guard !text.contains(where: \.isNewline), let program = text.split(separator: " ").first else { return false }
        return commandPrograms.contains(String(program))
    }

    /// The programs a fix that's a command starts with.
    static let commandPrograms: Set<String> = ["xcrun", "xcodebuild", "defaults", "open", "killall", "plutil", "sleep", "echo", "mkdir"]
}
