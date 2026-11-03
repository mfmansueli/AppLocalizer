//
//  StudioExtrasPreview.swift
//  AppLocalizer
//

import Foundation

/// What the new set adds to the App Store preview in a language on iPhone
/// or iPad: the header on top of the product page, the search results
/// artwork, and the App Preview first among the screenshots.
struct StudioExtrasPreview: Hashable {
    var header: StudioArtworkItem?
    var search: StudioArtworkItem?
    var appPreview: StudioPreviewTile?

    /// "Search shows this artwork where Apple supports it; elsewhere, the
    /// first screenshots."
    static let searchNote = String(localized: "Search shows this artwork where Apple supports it; elsewhere, the first screenshots.")
}
