//
//  ArtworkPromptFacts.swift
//  AppLocalizer
//

import Foundation

/// What the prompts know of the app beyond the run: its App Store page
/// (from the brief's aboutTheApp), what the assistant read of its look in
/// the project, its design project, its age rating, and the captions the
/// screens carry.
struct ArtworkPromptFacts: Hashable, Sendable {
    var profile: AutopilotAppProfile?
    var look: AppLookProfile?
    var designProject: DesignProject?
    /// "4+"; nil when it can't be read.
    var ageRating: String?
    /// Each screen's caption in the primary language, by slot.
    var captions: [Int: String] = [:]
    /// The icon is attached to get_design_brief.
    var hasIcon = true
}
