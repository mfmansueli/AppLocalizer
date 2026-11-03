//
//  StudioArtworkItem.swift
//  AppLocalizer
//

import Foundation

/// A header or search image the App Store preview shows: what
/// `ArtworkThumbnail` draws.
struct StudioArtworkItem: Hashable {
    var kind: AutopilotArtworkKind
    var template: ScreenshotTemplate
    var locale: String
    var headline: String
    var slots: [Int]
    var captures: [Int: ScreenshotCapture]
    /// What the search artwork shows.
    var shows: AutopilotArtworkShow = .phone
    /// It's a motion loop's poster: "0:20 loop" on it.
    var isMotion = false
}
