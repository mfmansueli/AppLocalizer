//
//  ArtworkTextKey.swift
//  AppLocalizer
//

import Foundation

/// A placement's text in one language: a Search results or Header cell.
struct ArtworkTextKey: Hashable, Sendable, Identifiable {
    var locale: String
    var role: ArtworkTextRole

    var id: String { "\(locale).\(role.rawValue)" }
}
