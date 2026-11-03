//
//  AutopilotArtworkTextNeed.swift
//  AppLocalizer
//

import Foundation

/// A placement's text the assistant writes or shortens in Localize: a
/// language without a search headline, or a text too long for its image
/// even at its smallest.
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
}
