//
//  AutopilotScreenSuggestions.swift
//  AppLocalizer
//

import Foundation

/// The assistant's answer to Suggest Screens, shown under the plan's
/// screens until the person closes it; or screens it suggested outside
/// Suggest Screens, kept for the app's next plan (`AutopilotPlanProposals`).
struct AutopilotScreenSuggestions: Codable, Hashable, Sendable {
    /// What the person asked for, if anything.
    var ask: String?
    var client: String
    var items: [AutopilotScreenSuggestion]
    var receivedAt: Date
    /// Apple Watch, for its own screens; nil for the set's, on iPhone and
    /// iPad.
    var displayType: ScreenshotDisplayType?
    /// The proposal's ID when they were sent outside Suggest Screens and
    /// wait for the next plan; nil for Suggest Screens' answer.
    var id: String?

    /// The device they're added to: iPhone stands for the set.
    var device: ScreenshotDisplayType { displayType ?? .iPhone }

    /// The ones not dismissed: open, or added ("Added").
    var shown: [AutopilotScreenSuggestion] { items.filter { $0.status != .dismissed } }

    /// The ones still to add or dismiss.
    var open: [AutopilotScreenSuggestion] { items.filter { $0.status == .open } }
}
