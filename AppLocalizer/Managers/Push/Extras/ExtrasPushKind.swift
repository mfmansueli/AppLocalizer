//
//  ExtrasPushKind.swift
//  AppLocalizer
//

import Foundation

/// What an extra is on the App Store page: artwork (the product page
/// header, search results, or one 16:9 image for both), the artwork's
/// motion loop, or an App Preview video.
enum ExtrasPushKind: Hashable, Sendable {
    /// An image placed under each of these placement types, e.g.
    /// `PRODUCT_PAGE_HEADER_ASSET`. It takes the place of whatever is in
    /// its slot.
    case artwork(placementTypes: [String])
    /// A header or search image's motion loop: a silent movie placed like
    /// the image, its first frame the poster. (Apple's API takes artwork
    /// videos as video assets; that's assumed here.)
    case motionArtwork(placementTypes: [String])
    /// A video shown first among the device's App Previews, with its
    /// poster frame at this time code, e.g. `00:00:05:00`.
    case appPreview(posterTimeCode: String)

    static let productPageHeader = "PRODUCT_PAGE_HEADER_ASSET"
    static let searchResults = "APP_STORE_SEARCH_RESULTS_ASSET"
    static let appPreviewPlacement = "APP_PREVIEW"
    /// A motion loop's poster is its first frame.
    static let loopPosterTimeCode = "00:00:00:00"

    /// What App Store Connect allows per App Preview group on a version.
    static let defaultPreviewLimit = 3

    var media: AssetLibraryMedia {
        switch self {
        case .artwork: .image
        case .motionArtwork, .appPreview: .video
        }
    }

    var placementTypes: [String] {
        switch self {
        case let .artwork(placementTypes), let .motionArtwork(placementTypes): placementTypes
        case .appPreview: [Self.appPreviewPlacement]
        }
    }

    /// The library category the asset is uploaded under.
    var category: String {
        switch self {
        case .artwork, .motionArtwork: "CREATIVE_ASSETS"
        case .appPreview: "APP_SCREENSHOTS_AND_PREVIEWS"
        }
    }

    /// "the product page header", "search results", "App Previews".
    static func name(ofPlacementType placementType: String) -> String {
        switch placementType {
        case productPageHeader: String(localized: "the product page header")
        case searchResults: String(localized: "search results")
        case appPreviewPlacement: String(localized: "App Previews")
        default: placementType
        }
    }
}
