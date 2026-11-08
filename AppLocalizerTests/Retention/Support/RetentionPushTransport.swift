//
//  RetentionPushTransport.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// App Store Connect for a retention push: requests go to a
/// `FakePushTransport` and the Asset Library calls to a `FakeAssetLibrary`,
/// as the real client takes both. Nothing reaches the network.
final class RetentionPushTransport: PushTransport, AssetLibraryPushing {
    let push: FakePushTransport
    let library: FakeAssetLibrary

    init(push: FakePushTransport, library: FakeAssetLibrary = FakeAssetLibrary()) {
        self.push = push
        self.library = library
    }

    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        try await push.send(request)
    }

    func fetch(_ path: String) async throws -> AppStoreConnectResponse {
        try await push.fetch(path)
    }

    func assetLibraryID(appID: StoreApp.ID) async throws -> String {
        try await library.assetLibraryID(appID: appID)
    }

    func assetLibraryRefData() async throws -> AssetLibraryRefData {
        try await library.assetLibraryRefData()
    }

    func reserveAssetLibraryImage(
        libraryID: String, fileName: String, fileSize: Int, category: String, referenceName: String
    ) async throws -> AssetLibraryAssetReservation {
        try await library.reserveAssetLibraryImage(
            libraryID: libraryID, fileName: fileName, fileSize: fileSize, category: category, referenceName: referenceName
        )
    }

    func reserveAssetLibraryVideo(
        libraryID: String, fileName: String, fileSize: Int, category: String, referenceName: String, previewFrameTimeCode: String?
    ) async throws -> AssetLibraryAssetReservation {
        try await library.reserveAssetLibraryVideo(
            libraryID: libraryID, fileName: fileName, fileSize: fileSize, category: category, referenceName: referenceName,
            previewFrameTimeCode: previewFrameTimeCode
        )
    }

    func upload(_ operation: ScreenshotUploadOperation, data: Data, progress: @escaping @Sendable (Int64) -> Void) async throws {
        try await library.upload(operation, data: data, progress: progress)
    }

    func commitAssetLibraryAsset(_ asset: AssetLibraryAsset) async throws {
        try await library.commitAssetLibraryAsset(asset)
    }

    func assetLibraryAssetState(_ asset: AssetLibraryAsset) async throws -> AssetLibraryAssetStatus {
        try await library.assetLibraryAssetState(asset)
    }

    func assetLibraryPlacements(localizationID: String, placementType: String, placementGroup: String?) async throws -> [AssetLibraryPlacement] {
        try await library.assetLibraryPlacements(localizationID: localizationID, placementType: placementType, placementGroup: placementGroup)
    }

    func deleteAssetLibraryPlacement(id: String) async throws {
        try await library.deleteAssetLibraryPlacement(id: id)
    }

    func createAssetLibraryPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, localizationID: String
    ) async throws -> AssetLibraryPlacement {
        try await library.createAssetLibraryPlacement(
            placementType: placementType, placementGroup: placementGroup, asset: asset, localizationID: localizationID
        )
    }

    func orderAssetLibraryPlacements(_ ids: [String], placementGroup: String, localizationID: String) async throws {
        try await library.orderAssetLibraryPlacements(ids, placementGroup: placementGroup, localizationID: localizationID)
    }
}
