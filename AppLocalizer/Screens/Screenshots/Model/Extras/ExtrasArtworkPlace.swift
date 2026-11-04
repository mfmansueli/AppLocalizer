//
//  ExtrasArtworkPlace.swift
//  AppLocalizer
//

import Foundation

/// How one place's artwork was drawn: its direction, look, Claude Design
/// page, what it shows, the screen it shows and whether it moves. A run
/// that makes only the header or only search results keeps the other
/// place's this way, so the preview draws it as it was made.
struct ExtrasArtworkPlace: Codable, Hashable, Sendable {
    var kind: AutopilotArtworkKind
    var directionName: String
    var template: ScreenshotTemplate?
    /// Its Claude Design page; nil when it was drawn from `template`.
    var page: String?
    var shows: AutopilotArtworkShow?
    var searchSlot: Int
    var motion: AutopilotArtworkMotion?
}
