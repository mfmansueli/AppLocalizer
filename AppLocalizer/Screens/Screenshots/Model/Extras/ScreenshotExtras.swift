//
//  ScreenshotExtras.swift
//  AppLocalizer
//

import Foundation

/// What an Autopilot run made beside the screenshots: the product page
/// header and search results artwork in each language, and the App
/// Previews. Their files are in the app's Extras folder, named by
/// checksum; they wait in Review & Push like the screenshots.
struct ScreenshotExtras: Codable, Hashable, Sendable {
    /// The direction they're made in.
    var directionName: String
    var madeAt: Date
    /// Nil when no artwork was made.
    var artworkSize: AutopilotArtworkSize?
    /// The artwork's look: the direction's own for it, else its template.
    var artworkTemplate: ScreenshotTemplate?
    /// The slot whose caption and capture the search image shows.
    var searchSlot: Int = 0
    /// What the search artwork shows; nil (sets from before) is a phone.
    var artworkShows: AutopilotArtworkShow?
    /// The artwork moves: each image is a loop's poster.
    var artworkMotion: AutopilotArtworkMotion?
    var artwork: [ExtrasArtworkFile] = []
    /// Nil when no App Preview was made.
    var previewLanguages: AutopilotPreviewLanguages?
    /// The App Preview's look: the direction's own for it, else its template.
    var previewTemplate: ScreenshotTemplate?
    var previews: [ExtrasPreviewFile] = []
    /// What was pushed, by item ID: the checksum App Store Connect has.
    var pushedChecksums: [String: String]?
    /// The Product Page Optimization variant, once one was made.
    var variant: ExtrasArtworkVariant?
    /// The App Previews' music; nil in sets from before it.
    var previewMusic: AutopilotPreviewMusic?
    /// Discarded in Review & Push, by item ID: the checksum that stays off
    /// App Store Connect. A file made again comes back to review.
    var discardedChecksums: [String: String]?

    var hasArtwork: Bool { artworkSize != nil && !artwork.isEmpty }
    var hasPreviews: Bool { !previews.isEmpty }

    /// The artwork of `kind` in `locale`.
    func artwork(_ kind: AutopilotArtworkKind, locale: String) -> ExtrasArtworkFile? {
        artwork.first { $0.kind == kind && $0.locale == locale }
    }

    /// The App Preview a language shows on a device: its own, else the
    /// primary language's.
    func preview(on display: ScreenshotDisplayType, locale: String, primary: String) -> ExtrasPreviewFile? {
        previews.first { $0.displayType == display && $0.locale == locale }
            ?? previews.first { $0.displayType == display && $0.locale == primary }
    }

    /// Languages whose headline doesn't fit the artwork.
    var tooLongLocales: [String] {
        Array(Set(artwork.filter { !$0.fits }.map(\.locale))).sorted()
    }
}
