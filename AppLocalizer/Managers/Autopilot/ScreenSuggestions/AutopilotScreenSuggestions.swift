//
//  AutopilotScreenSuggestions.swift
//  AppLocalizer
//

import Foundation

/// The assistant's answer to Suggest Screens, shown under the plan's
/// screens until the person closes it.
struct AutopilotScreenSuggestions: Codable, Hashable, Sendable {
    /// What the person asked for, if anything.
    var ask: String?
    var client: String
    var items: [AutopilotScreenSuggestion]
    var receivedAt: Date

    /// The ones not dismissed: open, or added ("Added").
    var shown: [AutopilotScreenSuggestion] { items.filter { $0.status != .dismissed } }
}
