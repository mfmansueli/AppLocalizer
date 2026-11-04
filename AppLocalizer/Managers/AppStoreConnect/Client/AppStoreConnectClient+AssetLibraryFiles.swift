//
//  AppStoreConnectClient+AssetLibraryFiles.swift
//  AppLocalizer
//

import Foundation

/// The library sheet's calls: listing the app's library, counting a file's
/// placements and deleting a file.
extension AppStoreConnectClient {
    /// The most pages of each kind read: 200 files a page.
    private static let filePageLimit = 10

    func assetLibraryFiles(appID: StoreApp.ID) async throws -> [AssetLibraryFile] {
        let libraryID = try await assetLibraryID(appID: appID)
        var files: [AssetLibraryFile] = []
        for media in [AssetLibraryMedia.image, .video] {
            var path: String? = AssetLibraryRequests.filesPath(libraryID: libraryID, media: media)
            var pages = 0
            while let next = path, pages < Self.filePageLimit {
                let page = try await AssetLibraryRequests.files(in: fetch(next).data, media: media)
                files += page.files
                path = page.next?.absoluteString
                pages += 1
            }
        }
        return files.sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
    }

    func assetLibraryPlacementCount(_ asset: AssetLibraryAsset) async throws -> Int {
        try await AssetLibraryRequests.placementCount(in: fetch(AssetLibraryRequests.placementLinksPath(asset)).data)
    }

    func deleteAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws {
        _ = try await send(AssetLibraryRequests.deleteAsset(asset))
    }
}
