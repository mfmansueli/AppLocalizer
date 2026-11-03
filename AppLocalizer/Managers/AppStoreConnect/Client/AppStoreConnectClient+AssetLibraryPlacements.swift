//
//  AppStoreConnectClient+AssetLibraryPlacements.swift
//  AppLocalizer
//

import Foundation

/// Where library assets show on a version localization's page: listing,
/// creating, deleting and ordering placements.
extension AppStoreConnectClient {
    /// The most pages of placements read for one group; a group holds a
    /// handful.
    private static let placementPageLimit = 10

    /// The localization's placements of `placementType` (in
    /// `placementGroup` if given), in their order, each with its asset.
    func assetLibraryPlacements(localizationID: String, placementType: String, placementGroup: String?) async throws -> [AssetLibraryPlacement] {
        var path: String? = AssetLibraryRequests.placementsPath(localizationID: localizationID, placementType: placementType, placementGroup: placementGroup)
        var placements: [AssetLibraryPlacement] = []
        var pages = 0
        while let next = path, pages < Self.placementPageLimit {
            let page = try await AssetLibraryRequests.placements(in: fetch(next).data)
            placements += page.placements
            path = page.next?.absoluteString
            pages += 1
        }
        return placements
    }

    /// Takes a placement off the page; its asset stays in the library.
    func deleteAssetLibraryPlacement(id: String) async throws {
        _ = try await send(AssetLibraryRequests.deletePlacement(id: id))
    }

    /// Shows `asset` on the localization's page under `placementType` in
    /// `placementGroup`.
    func createAssetLibraryPlacement(
        placementType: String, placementGroup: String, asset: AssetLibraryAsset, localizationID: String
    ) async throws -> AssetLibraryPlacement {
        let request = AssetLibraryRequests.createPlacement(
            placementType: placementType, placementGroup: placementGroup, asset: asset, localizationID: localizationID
        )
        return try await AssetLibraryRequests.placement(in: send(request).data)
    }

    /// Puts a group's placements in this order.
    func orderAssetLibraryPlacements(_ ids: [String], placementGroup: String, localizationID: String) async throws {
        _ = try await send(AssetLibraryRequests.orderPlacements(ids, placementGroup: placementGroup, localizationID: localizationID))
    }
}
