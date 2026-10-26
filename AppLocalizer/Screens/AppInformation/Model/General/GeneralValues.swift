//
//  GeneralValues.swift
//  AppLocalizer
//

import Foundation

/// The General page's values: categories and content rights for the whole
/// app, copyright and release for one version. Both App Store Connect's
/// values and the ones shown with pending changes on top.
struct GeneralValues: Hashable, Sendable {
    /// Category IDs, e.g. `LIFESTYLE`; nil when not chosen.
    var primaryCategory: String?
    var secondaryCategory: String?
    /// Up to two Games subcategory IDs, for a game.
    var gamesSubcategories: [String] = []
    var contentRights: ContentRights?
    /// "I have the rights to use it": asked when the app uses third-party
    /// content. App Store Connect only stores the answer above, so a
    /// queued Yes waits for this before it can be pushed.
    var rightsConfirmed = false
    var copyright = ""
    var release: ReleaseOption?
    var earliestReleaseDate: Date?

    var isGame: Bool { primaryCategory == AppCategory.gamesID }

    /// The page column's line: "Lifestyle · Health & Fitness".
    var categorySummary: String {
        [primaryCategory, secondaryCategory].compactMap(\.self).map { AppCategory.name(for: $0) }.joined(separator: " · ")
    }
}
