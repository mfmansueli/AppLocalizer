//
//  AssetLibraryAssetReservation.swift
//  AppLocalizer
//

import Foundation

/// A reserved upload (`AWAITING_UPLOAD`): the new asset and where each
/// part of its file goes. The parts go to Apple's upload host, without the
/// API token.
struct AssetLibraryAssetReservation: Hashable, Sendable {
    var asset: AssetLibraryAsset
    var uploadOperations: [ScreenshotUploadOperation]

    var id: String { asset.id }
}
