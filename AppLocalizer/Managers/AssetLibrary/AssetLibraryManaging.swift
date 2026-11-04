//
//  AssetLibraryManaging.swift
//  AppLocalizer
//

import Foundation

/// What the library sheet asks App Store Connect: every file in an app's
/// App Asset Library, whether one is on a page, and deleting one. The API
/// client is the real one; DEBUG scenes and tests keep a library in
/// memory.
protocol AssetLibraryManaging: Sendable {
    /// Every image and video in the app's library, newest first.
    func assetLibraryFiles(appID: StoreApp.ID) async throws -> [AssetLibraryFile]
    /// How many placements show `asset` on a page.
    func assetLibraryPlacementCount(_ asset: AssetLibraryAsset) async throws -> Int
    func deleteAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws
}

extension AppStoreConnectClient: AssetLibraryManaging {}
