//
//  DebugAssetLibrary.swift
//  AppLocalizer
//

#if DEBUG
import Foundation
import Synchronization

/// The App Asset Library for DEBUG scenes: every upload is accepted and
/// processed at once, and each language's page takes it. Never contacts
/// App Store Connect.
final class DebugAssetLibrary: AssetLibraryPushing {
    private let delay: Duration
    private let nextID = Mutex(1)

    init(delay: Duration) {
        self.delay = delay
    }

    func assetLibraryID(appID: StoreApp.ID) async throws -> String { "debug-library-\(appID)" }

    func assetLibraryRefData() async throws -> AssetLibraryRefData {
        try AssetLibraryRefData(json: Data(Self.refDataJSON.utf8))
    }

    func reserveAssetLibraryImage(
        libraryID _: String, fileName _: String, fileSize: Int, category _: String, referenceName _: String
    ) async throws -> AssetLibraryAssetReservation {
        try await reserve(.image, fileSize: fileSize)
    }

    func reserveAssetLibraryVideo(
        libraryID _: String, fileName _: String, fileSize: Int, category _: String, referenceName _: String, previewFrameTimeCode _: String?
    ) async throws -> AssetLibraryAssetReservation {
        try await reserve(.video, fileSize: fileSize)
    }

    func upload(_ operation: ScreenshotUploadOperation, data _: Data, progress: @escaping @Sendable (Int64) -> Void) async throws {
        try await Task.sleep(for: delay)
        progress(Int64(operation.length))
    }

    func commitAssetLibraryAsset(_: AssetLibraryAsset) async throws {}

    func assetLibraryAssetState(_: AssetLibraryAsset) async throws -> AssetLibraryAssetStatus {
        AssetLibraryAssetStatus(state: "PREPARE_FOR_SUBMISSION")
    }

    func assetLibraryPlacements(localizationID _: String, placementType _: String, placementGroup _: String?) async throws -> [AssetLibraryPlacement] {
        []
    }

    func deleteAssetLibraryPlacement(id _: String) async throws {}

    func createAssetLibraryPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, localizationID: String
    ) async throws -> AssetLibraryPlacement {
        AssetLibraryPlacement(id: "debug-placement-\(asset.id)-\(localizationID)", placementType: placementType, placementGroup: placementGroup, asset: asset)
    }

    func orderAssetLibraryPlacements(_: [String], placementGroup _: String, localizationID _: String) async throws {}

    private func reserve(_ media: AssetLibraryMedia, fileSize: Int) async throws -> AssetLibraryAssetReservation {
        try await Task.sleep(for: delay)
        let id = nextID.withLock { next in
            defer { next += 1 }
            return "debug-\(media.rawValue)-\(next)"
        }
        let operation = ScreenshotUploadOperation(method: "PUT", url: "debug://upload/\(id)/1", offset: 0, length: fileSize)
        return AssetLibraryAssetReservation(asset: AssetLibraryAsset(id: id, media: media), uploadOperations: [operation])
    }

    /// Apple's reference data, cut down to the header, search results and
    /// iPhone and iPad App Previews.
    static let refDataJSON = """
    {"data": [{"type": "appAssetLibraryRefData", "id": "1", "attributes": {
      "features": [{"featureId": "APP_STORE_VERSIONS", "placementPolicies": [
        {"placementType": "APP_PREVIEW", "groupLimits": [{"groupIds": ["IPHONE_PREVIEW", "IPAD_PREVIEW"], "maxCount": 3}]},
        {"placementType": "PRODUCT_PAGE_HEADER_ASSET", "groupLimits": [{"groupIds": ["HEADER"], "maxCount": 1}]},
        {"placementType": "APP_STORE_SEARCH_RESULTS_ASSET", "groupLimits": [{"groupIds": ["SEARCH"], "maxCount": 1}]}
      ]}],
      "imageSpecs": [
        {"specId": "header", "dimensions": {"minWidth": 3840, "maxWidth": 3840, "minHeight": 1646, "maxHeight": 1646},
         "compatiblePlacementTypes": ["PRODUCT_PAGE_HEADER_ASSET"]},
        {"specId": "search", "dimensions": {"minWidth": 1920, "maxWidth": 3840, "minHeight": 1280, "maxHeight": 2560},
         "compatiblePlacementTypes": ["APP_STORE_SEARCH_RESULTS_ASSET"]},
        {"specId": "wide", "dimensions": {"minWidth": 5244, "maxWidth": 5244, "minHeight": 2950, "maxHeight": 2950},
         "compatiblePlacementTypes": ["PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"]}
      ],
      "videoSpecs": [
        {"specId": "iphone", "dimensions": {"minWidth": 886, "maxWidth": 886, "minHeight": 1920, "maxHeight": 1920},
         "compatiblePlacementTypes": ["APP_PREVIEW"]},
        {"specId": "ipad", "dimensions": {"minWidth": 1200, "maxWidth": 1200, "minHeight": 1600, "maxHeight": 1600},
         "compatiblePlacementTypes": ["APP_PREVIEW"]}
      ],
      "placementTypes": [
        {"placementTypeId": "PRODUCT_PAGE_HEADER_ASSET", "specMappings": [{"placementGroupId": "HEADER", "specs": ["header", "wide"]}]},
        {"placementTypeId": "APP_STORE_SEARCH_RESULTS_ASSET", "specMappings": [{"placementGroupId": "SEARCH", "specs": ["search", "wide"]}]},
        {"placementTypeId": "APP_PREVIEW", "specMappings": [
          {"placementGroupId": "IPHONE_PREVIEW", "specs": ["iphone"]}, {"placementGroupId": "IPAD_PREVIEW", "specs": ["ipad"]}
        ]}
      ]
    }}]}
    """
}
#endif
