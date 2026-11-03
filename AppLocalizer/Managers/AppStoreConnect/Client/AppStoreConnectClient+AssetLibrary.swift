//
//  AppStoreConnectClient+AssetLibrary.swift
//  AppLocalizer
//

import Foundation

/// The App Asset Library's uploads: the app's library, Apple's reference
/// data, and reserving, committing and checking an image or video. The
/// parts go up with `upload(_:data:progress:)`, like a screenshot's.
/// Placements live in `AppStoreConnectClient+AssetLibraryPlacements`.
extension AppStoreConnectClient {
    /// The ID of the app's asset library.
    func assetLibraryID(appID: StoreApp.ID) async throws -> String {
        try await AssetLibraryRequests.resourceID(in: fetch(AssetLibraryRequests.libraryPath(appID: appID)).data)
    }

    /// Where assets can go: specs, placement groups and their limits.
    func assetLibraryRefData() async throws -> AssetLibraryRefData {
        try await AssetLibraryRefData(json: fetch(AssetLibraryRequests.refDataPath).data)
    }

    /// Reserves an image upload of `fileSize` bytes, e.g. header artwork
    /// in the `CREATIVE_ASSETS` category.
    func reserveAssetLibraryImage(
        libraryID: String, fileName: String, fileSize: Int, category: String, referenceName: String
    ) async throws -> AssetLibraryAssetReservation {
        let request = AssetLibraryRequests.reserve(
            .image, libraryID: libraryID, fileName: fileName, fileSize: fileSize, category: category, referenceName: referenceName
        )
        return try await AssetLibraryRequests.reservation(in: send(request).data, media: .image)
    }

    /// Reserves a video upload, e.g. an App Preview in the
    /// `APP_SCREENSHOTS_AND_PREVIEWS` category with its poster frame at
    /// `00:00:05:00`.
    func reserveAssetLibraryVideo(
        libraryID: String, fileName: String, fileSize: Int, category: String, referenceName: String, previewFrameTimeCode: String?
    ) async throws -> AssetLibraryAssetReservation {
        let request = AssetLibraryRequests.reserve(
            .video, libraryID: libraryID, fileName: fileName, fileSize: fileSize, category: category, referenceName: referenceName,
            previewFrameTimeCode: previewFrameTimeCode
        )
        return try await AssetLibraryRequests.reservation(in: send(request).data, media: .video)
    }

    /// Tells Apple every part of `asset` is up, so it starts processing.
    func commitAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws {
        _ = try await send(AssetLibraryRequests.commit(asset))
    }

    /// Where `asset` is: still processing, ready to place, or failed with
    /// Apple's reasons.
    func assetLibraryAssetState(_ asset: AssetLibraryAsset) async throws -> AssetLibraryAssetStatus {
        try await AssetLibraryRequests.status(in: fetch(AssetLibraryRequests.statePath(asset)).data)
    }
}
