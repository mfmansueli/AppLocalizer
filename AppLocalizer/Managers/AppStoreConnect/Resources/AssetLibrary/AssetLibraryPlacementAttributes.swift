//
//  AssetLibraryPlacementAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appAssetLibraryPlacements` resource's attributes, read leniently.
struct AssetLibraryPlacementAttributes: Decodable, Sendable {
    var mediaType: String?
    var placementType: String?
    var placementGroup: String?
    /// `ASSET_PROCESSING`, `FAILED`, `PARENT_PREPARE_FOR_SUBMISSION`, …
    var state: String?
    var stateDetails: [AssetLibraryStateDetail] = []

    private enum CodingKeys: String, CodingKey {
        case mediaType, placementType, placementGroup, state, stateDetails
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mediaType = try? container.decodeIfPresent(String.self, forKey: .mediaType)
        placementType = try? container.decodeIfPresent(String.self, forKey: .placementType)
        placementGroup = try? container.decodeIfPresent(String.self, forKey: .placementGroup)
        state = try? container.decodeIfPresent(String.self, forKey: .state)
        stateDetails = AssetLibraryStateDetail.list(in: container, forKey: .stateDetails)
    }
}
