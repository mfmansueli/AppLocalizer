//
//  AssetLibraryPushing.swift
//  AppLocalizer
//

import Foundation

/// The App Asset Library calls an extras push makes: the library, Apple's
/// reference data, an upload's reserve, parts, commit and state, and the
/// placements on a version localization's page. The API client is the
/// real one; tests simulate App Store Connect.
protocol AssetLibraryPushing: Sendable {
    func assetLibraryID(appID: StoreApp.ID) async throws -> String
    func assetLibraryRefData() async throws -> AssetLibraryRefData
    func reserveAssetLibraryImage(
        libraryID: String, fileName: String, fileSize: Int, category: String, referenceName: String
    ) async throws -> AssetLibraryAssetReservation
    func reserveAssetLibraryVideo(
        libraryID: String, fileName: String, fileSize: Int, category: String, referenceName: String, previewFrameTimeCode: String?
    ) async throws -> AssetLibraryAssetReservation
    /// Sends one part of `data`, telling `progress` how many of the part's
    /// bytes went out. No API token goes with it.
    func upload(_ operation: ScreenshotUploadOperation, data: Data, progress: @escaping @Sendable (Int64) -> Void) async throws
    func commitAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws
    func assetLibraryAssetState(_ asset: AssetLibraryAsset) async throws -> AssetLibraryAssetStatus
    func assetLibraryPlacements(localizationID: String, placementType: String, placementGroup: String?) async throws -> [AssetLibraryPlacement]
    func deleteAssetLibraryPlacement(id: String) async throws
    func createAssetLibraryPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, localizationID: String
    ) async throws -> AssetLibraryPlacement
    func orderAssetLibraryPlacements(_ ids: [String], placementGroup: String, localizationID: String) async throws
}

extension AppStoreConnectClient: AssetLibraryPushing {}
