//
//  AutopilotArtworkTextUpdate.swift
//  AppLocalizer
//

import Foundation

/// A placement's text the assistant sent with `propose_captions`
/// (`placement` instead of `slot`); an empty header line removes it.
struct AutopilotArtworkTextUpdate: Hashable, Sendable {
    var locale: String
    var role: ArtworkTextRole
    var headline: String
}
