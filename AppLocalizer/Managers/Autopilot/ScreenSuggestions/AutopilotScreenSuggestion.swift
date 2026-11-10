//
//  AutopilotScreenSuggestion.swift
//  AppLocalizer
//

import Foundation

/// A screen the assistant suggests for the set: why, what shows it, how to
/// reach it and a caption. Shown to the person, never added on its own.
struct AutopilotScreenSuggestion: Codable, Hashable, Sendable, Identifiable {
    enum Status: String, Codable, Hashable, Sendable {
        case open
        case added
        case dismissed
    }

    var id: String
    /// "Insights".
    var name: String
    /// "New in 1.4 and in no screenshot yet."
    var reason: String
    /// "InsightsView.swift, 23 commits since v1.3"; nil when not given.
    var evidence: String?
    /// "tab “Insights” → wait for the mood chart".
    var steps: String
    /// The primary language's headline; empty lets the assistant write it.
    var caption: String
    var status: Status = .open

    /// Added to `display`'s screens as `id`, marked as suggested by
    /// `client`. Apple Watch's has no caption.
    func screen(id: String, on display: ScreenshotDisplayType, client: String) -> AutopilotScreen {
        AutopilotScreen(
            id: id, name: name, steps: steps, caption: display.hasCaptions ? caption : "", origin: .suggestion(client: client)
        )
    }

    /// The same screen as one named `other`, whatever the case.
    func isNamed(_ other: String) -> Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(other.trimmingCharacters(in: .whitespacesAndNewlines))
            == .orderedSame
    }
}
