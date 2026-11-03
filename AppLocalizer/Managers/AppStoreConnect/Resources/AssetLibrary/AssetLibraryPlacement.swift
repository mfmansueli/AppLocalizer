//
//  AssetLibraryPlacement.swift
//  AppLocalizer
//

import Foundation

/// A library asset placed on a version localization's App Store page: e.g.
/// its product page header, or an App Preview in a device's group.
/// Placements can't be changed; replacing one is a delete and a create.
struct AssetLibraryPlacement: Hashable, Sendable, Identifiable {
    var id: String
    var placementType: String?
    var placementGroup: String?
    var state: String?
    /// The asset it shows, when the response linked it.
    var asset: AssetLibraryAsset?

    var assetID: String? { asset?.id }

    init(id: String, placementType: String? = nil, placementGroup: String? = nil, state: String? = nil, asset: AssetLibraryAsset? = nil) {
        self.id = id
        self.placementType = placementType
        self.placementGroup = placementGroup
        self.state = state
        self.asset = asset
    }

    init(_ resource: ScreenshotAPIResource<AssetLibraryPlacementAttributes>) {
        let image = resource.related(AssetLibraryMedia.image.relationship).first.map { AssetLibraryAsset(id: $0.id, media: .image) }
        let video = resource.related(AssetLibraryMedia.video.relationship).first.map { AssetLibraryAsset(id: $0.id, media: .video) }
        self.init(
            id: resource.id,
            placementType: resource.attributes?.placementType,
            placementGroup: resource.attributes?.placementGroup,
            state: resource.attributes?.state,
            asset: image ?? video
        )
    }
}
