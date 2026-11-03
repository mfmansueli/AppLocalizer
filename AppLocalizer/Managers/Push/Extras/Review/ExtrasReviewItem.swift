//
//  ExtrasReviewItem.swift
//  AppLocalizer
//

import Foundation

/// One extra waiting in Review & Push: a header or search image, or an
/// App Preview, in one language, with what its checks found. An error (a
/// price, a URL, an award…) or a missing localization keeps it out of the
/// push; warnings don't.
struct ExtrasReviewItem: Hashable, Sendable, Identifiable {
    enum Content: Hashable, Sendable {
        case artwork(AutopilotArtworkKind)
        case appPreview(ScreenshotDisplayType, posterTimeCode: String)
    }

    /// The extra's ID in the document (`header-de-DE`, `iphone-de-DE`),
    /// which `pushedChecksums` is keyed by.
    var id: String
    var appID: StoreApp.ID
    var content: Content
    var locale: String
    var localeName: String
    /// The file's checksum: what App Store Connect has once it's pushed.
    var fileID: String
    var fileURL: URL
    /// The name it's uploaded under, e.g. `header-de-DE.png`.
    var fileName: String
    var pixelSize: PixelSize
    /// The artwork's line; nil for an App Preview.
    var headline: String?
    var checks: [ArtworkCheck] = []
    /// An App Preview's broken rules, each a sentence.
    var problems: [String] = []
    /// The version localization it goes on; nil when App Store Connect has
    /// none for the language yet.
    var localizationID: String?
    /// Artwork made as a motion loop: the movie the push sends, while
    /// `fileURL` stays the poster (the image) the tile shows.
    var loopFileURL: URL?

    var isMotion: Bool { loopFileURL != nil }

    var errors: [ArtworkCheck] { checks.filter(\.isError) }
    var warnings: [ArtworkCheck] { checks.filter { !$0.isError } }

    var isBlocked: Bool { blockReason != nil }

    /// Why it can't go, in a sentence: the first error, the first broken
    /// App Preview rule, or the missing localization.
    var blockReason: String? {
        if let error = errors.first { return error.text }
        if let problem = problems.first { return problem }
        if localizationID == nil {
            return String(localized: "App Store Connect has no \(localeName) localization on this version yet.")
        }
        return nil
    }

    /// "Header 21:9", "iPhone App Preview".
    var kindTitle: String {
        switch content {
        case let .artwork(kind): "\(kind.title) \(kind.ratioTitle)"
        case let .appPreview(display, _): String(localized: "\(display.shortTitle) App Preview")
        }
    }

    /// "German · Header 21:9".
    var title: String { "\(localeName) · \(kindTitle)" }

    var artworkKind: AutopilotArtworkKind? {
        if case let .artwork(kind) = content { return kind }
        return nil
    }

    /// What the push sends, or nil while it's blocked.
    var pushItem: ExtrasPushItem? {
        guard !isBlocked, let localizationID else { return nil }
        let kind: ExtrasPushKind = switch content {
        case let .artwork(artwork) where isMotion: .motionArtwork(placementTypes: artwork.placementTypes)
        case let .artwork(artwork): .artwork(placementTypes: artwork.placementTypes)
        case let .appPreview(_, posterTimeCode): .appPreview(posterTimeCode: posterTimeCode)
        }
        let name = isMotion ? (fileName as NSString).deletingPathExtension + "." + ExtrasArtworkLoop.pathExtension : fileName
        let motion = isMotion ? String(localized: " · motion") : ""
        return ExtrasPushItem(
            id: id, appID: appID, title: title, localizationID: localizationID, kind: kind, fileName: name,
            pixelSize: pixelSize, referenceName: "Autopilot · \(locale) · \(kindTitle)\(motion)", fileURL: loopFileURL ?? fileURL
        )
    }
}
