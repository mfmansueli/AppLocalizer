//
//  CaptureTextIssue.swift
//  AppLocalizer
//

import Foundation

/// Something the text in a capture gives away: a screen that isn't in its
/// language, a label cut off, or a system prompt in the way. Each says it
/// to the person and tells the assistant how to fix it.
enum CaptureTextIssue: Hashable, Sendable {
    /// Most of the text is in the primary language or English, not the
    /// capture's: the screen, or its sample data, isn't localized.
    case otherLanguage(found: String, expected: String)
    /// Labels cut off with an ellipsis, beyond the primary language's.
    case cutOff([String])
    /// The app's name in quotes: a permission or notification prompt.
    case systemPrompt(String)

    /// "Most of its text is in English, not German."
    var message: String {
        switch self {
        case let .otherLanguage(found, expected):
            String(localized: "Most of its text is in \(found), not \(expected).")
        case let .cutOff(lines):
            String(localized: "Cut-off text: \(Self.quoted(lines)).")
        case let .systemPrompt(line):
            String(localized: "A system prompt is showing: “\(line)”.")
        }
    }

    /// What the assistant does about it before the next attempt.
    var fix: String {
        switch self {
        case let .otherLanguage(found, expected):
            "Most of the text reads as \(found), not \(expected): the screen or its sample data isn't in \(expected). Launch with this "
                + "locale's launchArguments, use sample data in \(expected), and capture it again."
        case .cutOff:
            "Text is cut off with an ellipsis where the primary language's isn't. Capture a state where it fits, or note it in report_capture "
                + "so the person can ask for a shorter translation in the app."
        case .systemPrompt:
            "A system prompt is on screen. Grant the permission with xcrun simctl privacy, or answer the prompt (Don't Allow for "
                + "notifications, Ask App Not to Track for tracking), and capture it again."
        }
    }

    /// "“Einträge durchsu…”, “Wochenübersi…”", at most three.
    private static func quoted(_ lines: [String]) -> String {
        let shown = lines.prefix(3).map { "“\($0)”" }
        let more = lines.count - shown.count
        return more > 0 ? shown.joined(separator: ", ") + String(localized: " and \(more) more") : shown.joined(separator: ", ")
    }
}
