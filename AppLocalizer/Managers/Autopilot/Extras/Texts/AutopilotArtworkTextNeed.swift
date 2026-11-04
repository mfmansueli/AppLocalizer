//
//  AutopilotArtworkTextNeed.swift
//  AppLocalizer
//

import Foundation

/// A placement's text the assistant writes or shortens in Localize: a
/// language without a search headline or without one of the page's
/// phrases, or a text too long for its image even at its smallest.
struct AutopilotArtworkTextNeed: Codable, Hashable, Sendable {
    enum Problem: String, Codable, Hashable, Sendable {
        case missing
        case tooLong = "too_long"
    }

    var locale: String
    var role: ArtworkTextRole
    var problem: Problem
    /// The text now; empty when it's missing.
    var headline: String = ""
    /// One of the page's phrases, by its words in the primary language
    /// (`ArtworkTextBook.phrases`), instead of the placement's headline;
    /// `role` is the image it was measured on.
    var phrase: String?

    var isPhrase: Bool { phrase != nil }
}
