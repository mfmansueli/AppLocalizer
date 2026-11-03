//
//  AutopilotScreen.swift
//  AppLocalizer
//

import Foundation

/// One screen of the plan: its name, how the assistant reaches it, and the
/// caption it goes with. Its position in the plan is its slot.
struct AutopilotScreen: Codable, Hashable, Sendable, Identifiable {
    /// Stable within a run, e.g. `today`.
    var id: String
    /// "Today".
    var name: String
    /// "tab “Week” → scroll to top"; empty until the assistant (or the
    /// person) writes it.
    var steps: String
    /// The primary language's headline, e.g. "Write a little every day".
    var caption: String
    /// On Apple Vision Pro: the iPhone screen whose moment (pick) and
    /// caption this window shows.
    var sourceScreenID: String?
    /// Who added it to the plan, by hand or from a suggestion; nil for the
    /// plan's own screens.
    var origin: AutopilotScreenOrigin?
    /// The assistant works out the steps and adds them to the app's UI
    /// tests ("Let Claude Code work out the steps"); nil means no.
    var worksOutSteps: Bool?

    init(
        id: String? = nil, name: String, steps: String = "", caption: String = "", sourceScreenID: String? = nil,
        origin: AutopilotScreenOrigin? = nil, worksOutSteps: Bool? = nil
    ) {
        self.id = id ?? Self.identifier(for: name)
        self.name = name
        self.steps = steps
        self.caption = caption
        self.sourceScreenID = sourceScreenID
        self.origin = origin
        self.worksOutSteps = worksOutSteps
    }

    /// "Photo entry" → `photo-entry`.
    static func identifier(for name: String) -> String {
        let folded = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        let parts = folded.split { !$0.isLetter && !$0.isNumber }
        return parts.isEmpty ? UUID().uuidString.lowercased() : parts.joined(separator: "-")
    }
}
