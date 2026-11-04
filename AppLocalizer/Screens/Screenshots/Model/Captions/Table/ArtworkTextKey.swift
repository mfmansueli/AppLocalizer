//
//  ArtworkTextKey.swift
//  AppLocalizer
//

import Foundation

/// A placement's text in one language: a Search results or Header cell;
/// with `phrase`, one of the pages' phrases there instead.
struct ArtworkTextKey: Hashable, Sendable, Identifiable {
    var locale: String
    /// The placement, or for a phrase the one on the canvas it's written on.
    var role: ArtworkTextRole
    /// The phrase's words in the primary language: its key in
    /// `ArtworkTextBook.phrases`.
    var phrase: String?

    var id: String { phrase.map { "\(locale).text.\($0)" } ?? "\(locale).\(role.rawValue)" }
}
