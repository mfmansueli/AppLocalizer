//
//  AutopilotDirection.swift
//  AppLocalizer
//

import Foundation

/// One design direction for the set: an AppLocalizer template from the
/// design AI, or one of AppLocalizer's starters.
struct AutopilotDirection: Codable, Hashable, Sendable, Identifiable {
    var id: String
    /// "Quiet Indigo".
    var name: String
    /// "Your indigo, with a New York headline over the device."
    var rationale: String
    /// Where it came from; `.none` for AppLocalizer's starters.
    var source: DesignProjectKind
    /// The assistant that sent it; nil for a starter.
    var client: String?
    var template: ScreenshotTemplate
    /// The header and search artwork's look, when the design AI sent one of
    /// its own (`extrasTemplates.artwork`); nil uses `template`'s.
    var artworkTemplate: ScreenshotTemplate?
    /// The App Preview's captions and end card look, when sent
    /// (`extrasTemplates.appPreview`); nil uses `template`'s.
    var previewTemplate: ScreenshotTemplate?
    /// Where to refine it, e.g. the Claude Design project's link.
    var link: String?
    /// Changed after "Ask for changes".
    var isRevised = false
    /// Language checks with the captions: too long, mirrors, fits.
    var checks: [AutopilotDirectionCheck] = []
    var receivedAt: Date

    /// The artwork's look: its own, else the screenshots'.
    var artworkLook: ScreenshotTemplate { artworkTemplate ?? template }

    /// The App Preview's look: its own, else the screenshots'.
    var previewLook: ScreenshotTemplate { previewTemplate ?? template }

    /// The badge's label: "Claude Design" or "Starter".
    var sourceTitle: String {
        source == .none ? String(localized: "Starter") : source.title
    }
}
