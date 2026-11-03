//
//  AssetLibraryMedia.swift
//  AppLocalizer
//

import Foundation

/// Whether an App Asset Library asset is an image (header and search
/// artwork, screenshots) or a video (App Previews). Each has its own
/// endpoints, and a placement links to it under its own relationship.
enum AssetLibraryMedia: String, Codable, Hashable, Sendable {
    case image
    case video

    /// The JSON:API type: `appAssetLibraryImages` or `appAssetLibraryVideos`.
    var resourceType: String {
        switch self {
        case .image: "appAssetLibraryImages"
        case .video: "appAssetLibraryVideos"
        }
    }

    /// The placement's relationship to the asset: `image` or `video`.
    var relationship: String { rawValue }

    /// `/v1/appAssetLibraryImages` or `/v1/appAssetLibraryVideos`.
    var path: String { "/v1/\(resourceType)" }
}
