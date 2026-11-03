//
//  AssetLibraryRequests.swift
//  AppLocalizer
//

import Foundation

/// The App Asset Library requests (App Store Connect API 4.5) and what's
/// read from their responses. An asset is reserved in the app's library,
/// its parts uploaded, committed and processed; then it's placed on a
/// version localization's page under a placement type and group.
/// Placements can't be edited, so replacing one is a delete and a create.
enum AssetLibraryRequests {
    /// `GET /v1/apps/{id}/assetLibrary`: the app's library.
    static func libraryPath(appID: StoreApp.ID) -> String {
        "/v1/apps/\(appID)/assetLibrary"
    }

    /// `GET /v1/appAssetLibraryRefData` with every part a push reads.
    static let refDataPath = "/v1/appAssetLibraryRefData?fields%5BappAssetLibraryRefData%5D="
        + "features,placementProfileGroups,imageSpecs,videoSpecs,placementTypes"

    /// `POST /v1/appAssetLibraryImages` or `…Videos`: reserves an upload of
    /// `fileSize` bytes in the library. A video can name its poster frame,
    /// e.g. `00:00:05:00`.
    static func reserve(
        _ media: AssetLibraryMedia, libraryID: String, fileName: String, fileSize: Int, category: String, referenceName: String,
        previewFrameTimeCode: String? = nil
    ) -> PushRequest {
        var attributes: [String: Any] = ["fileName": fileName, "fileSize": fileSize, "category": category, "referenceName": referenceName]
        if media == .video, let previewFrameTimeCode { attributes["previewFrameTimeCode"] = previewFrameTimeCode }
        return request(.post, media.path, [
            "data": [
                "type": media.resourceType,
                "attributes": attributes,
                "relationships": ["assetLibrary": ["data": ["type": "appAssetLibraries", "id": libraryID]]],
            ],
        ])
    }

    /// `PATCH /v1/appAssetLibraryImages/{id}`: every part is up. Apple
    /// checks the file against the reserved size; there's no checksum.
    static func commit(_ asset: AssetLibraryAsset) -> PushRequest {
        request(.patch, "\(asset.media.path)/\(asset.id)", [
            "data": ["type": asset.media.resourceType, "id": asset.id, "attributes": ["uploaded": true]],
        ])
    }

    /// `GET` one asset's state and Apple's details about it.
    static func statePath(_ asset: AssetLibraryAsset) -> String {
        "\(asset.media.path)/\(asset.id)?fields%5B\(asset.media.resourceType)%5D=state,stateDetails"
    }

    /// `GET /v1/appStoreVersionLocalizations/{id}/placements` of one type,
    /// and group if given, in their order, with the asset each shows.
    static func placementsPath(localizationID: String, placementType: String, placementGroup: String?) -> String {
        var query = ["filter%5BplacementType%5D=\(placementType)"]
        if let placementGroup { query.append("filter%5BplacementGroup%5D=\(encoded(placementGroup))") }
        query += ["sort=placementGroupPosition", "include=image,video", "limit=200"]
        return "/v1/appStoreVersionLocalizations/\(localizationID)/placements?" + query.joined(separator: "&")
    }

    /// `POST /v1/appAssetLibraryPlacements`: shows `asset` on the
    /// localization's page.
    static func createPlacement(placementType: String, placementGroup: String, asset: AssetLibraryAsset, localizationID: String) -> PushRequest {
        request(.post, "/v1/appAssetLibraryPlacements", [
            "data": [
                "type": "appAssetLibraryPlacements",
                "attributes": ["placementType": placementType, "placementGroup": placementGroup],
                "relationships": [
                    asset.media.relationship: ["data": ["type": asset.media.resourceType, "id": asset.id]],
                    "appStoreVersionLocalization": ["data": ["type": "appStoreVersionLocalizations", "id": localizationID]],
                ],
            ],
        ])
    }

    /// `DELETE /v1/appAssetLibraryPlacements/{id}`. The asset stays in the
    /// library.
    static func deletePlacement(id: String) -> PushRequest {
        PushRequest(method: .delete, path: "/v1/appAssetLibraryPlacements/\(id)", body: nil)
    }

    /// `POST /v1/appAssetLibraryPlacementOrderingRequests`: a group's
    /// placements in this order.
    static func orderPlacements(_ ids: [String], placementGroup: String, localizationID: String) -> PushRequest {
        request(.post, "/v1/appAssetLibraryPlacementOrderingRequests", [
            "data": [
                "type": "appAssetLibraryPlacementOrderingRequests",
                "attributes": ["placementGroup": placementGroup],
                "relationships": [
                    "orderedPlacements": ["data": ids.map { ["type": "appAssetLibraryPlacements", "id": $0] }],
                    "appStoreVersionLocalization": ["data": ["type": "appStoreVersionLocalizations", "id": localizationID]],
                ],
            ],
        ])
    }

    // MARK: - Responses

    /// The `data.id` of a single-resource response, e.g. the library's.
    static func resourceID(in data: Data) throws -> String {
        try document(AssetLibraryAssetAttributes.self, in: data).data.id
    }

    /// The reserved asset and its upload operations.
    static func reservation(in data: Data, media: AssetLibraryMedia) throws -> AssetLibraryAssetReservation {
        let resource = try document(AssetLibraryAssetAttributes.self, in: data).data
        return AssetLibraryAssetReservation(
            asset: AssetLibraryAsset(id: resource.id, media: media), uploadOperations: resource.attributes?.uploadOperations ?? []
        )
    }

    static func status(in data: Data) throws -> AssetLibraryAssetStatus {
        try document(AssetLibraryAssetAttributes.self, in: data).data.attributes?.status ?? AssetLibraryAssetStatus(state: nil)
    }

    /// One page of placements, and the next page's URL if there's more.
    static func placements(in data: Data) throws -> (placements: [AssetLibraryPlacement], next: URL?) {
        do {
            let page = try JSONDecoder().decode(ScreenshotAPIDocument<AssetLibraryPlacementAttributes, AssetLibraryAssetAttributes>.self, from: data)
            return (page.data.map(AssetLibraryPlacement.init), page.links?.next)
        } catch {
            throw AppStoreConnectError.unexpectedPayload
        }
    }

    static func placement(in data: Data) throws -> AssetLibraryPlacement {
        try AssetLibraryPlacement(document(AssetLibraryPlacementAttributes.self, in: data).data)
    }

    // MARK: - Helpers

    private static func document<Attributes: Decodable & Sendable>(
        _: Attributes.Type, in data: Data
    ) throws -> ScreenshotAPISingleDocument<Attributes> {
        do {
            return try JSONDecoder().decode(ScreenshotAPISingleDocument<Attributes>.self, from: data)
        } catch {
            throw AppStoreConnectError.unexpectedPayload
        }
    }

    /// A placement group ID as a query value. Apple's are plain
    /// `UPPER_SNAKE` IDs, but nothing else may break the query.
    private static func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-_.~"))) ?? value
    }

    private static func request(_ method: PushRequest.Method, _ path: String, _ object: [String: Any]) -> PushRequest {
        let body = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
        return PushRequest(method: method, path: path, body: body)
    }
}
