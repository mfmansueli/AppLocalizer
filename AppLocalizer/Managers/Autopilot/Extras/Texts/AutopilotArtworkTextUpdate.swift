//
//  AutopilotArtworkTextUpdate.swift
//  AppLocalizer
//

import Foundation

/// A placement's text the assistant sent with `propose_captions`
/// (`placement` instead of `slot`); an empty header line removes it. With
/// `phrase`, one of the pages' phrases in `locale` instead.
struct AutopilotArtworkTextUpdate: Hashable, Sendable {
    var locale: String
    var role: ArtworkTextRole
    var headline: String
    /// The phrase's words in the primary language, its key in
    /// `ArtworkTextBook.phrases`.
    var phrase: String?
}
