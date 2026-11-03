//
//  AssetLibraryRefData.swift
//  AppLocalizer
//

import Foundation

/// What `GET /v1/appAssetLibraryRefData` says about where assets can go:
/// each spec's sizes, which specs each placement group takes per placement
/// type, and how many placements a group holds. A push reads it once to
/// find the groups a file of its size belongs in, rather than hard-coding
/// Apple's group IDs. Parsing lives in `AssetLibraryRefData+Parsing`.
struct AssetLibraryRefData: Hashable, Sendable {
    var specs: [AssetLibrarySpec] = []
    var mappings: [AssetLibrarySpecMapping] = []
    var groupLimits: [AssetLibraryGroupLimit] = []

    /// The feature whose limits apply to a version's App Store page.
    static let appStoreVersionsFeature = "APP_STORE_VERSIONS"

    /// The placement groups that take a file of `pixelSize` under
    /// `placementType`, in the reference data's order; empty when none
    /// does.
    func placementGroups(for placementType: String, pixelSize: PixelSize, isVideo: Bool) -> [String] {
        let specs = specsByID(isVideo: isVideo)
        var groups: [String] = []
        for mapping in mappings where mapping.placementType == placementType && !groups.contains(mapping.placementGroup) {
            if mapping.specIDs.contains(where: { specs[$0]?.accepts(pixelSize) == true }) {
                groups.append(mapping.placementGroup)
            }
        }
        return groups
    }

    /// The exact sizes `placementType` takes, for a message when a file
    /// fits none of them, e.g. 3840 × 1646 and 5244 × 2950.
    func acceptedSizes(for placementType: String, isVideo: Bool) -> [PixelSize] {
        let specs = specsByID(isVideo: isVideo)
        var sizes: [PixelSize] = []
        for mapping in mappings where mapping.placementType == placementType {
            for size in mapping.specIDs.compactMap({ specs[$0]?.exactSize }) where !sizes.contains(size) {
                sizes.append(size)
            }
        }
        return sizes
    }

    /// How many placements of `placementType` `placementGroup` holds for
    /// `feature`; nil when the reference data doesn't say.
    func groupLimit(placementType: String, placementGroup: String, feature: String = Self.appStoreVersionsFeature) -> Int? {
        let matching = groupLimits.filter { limit in
            (limit.placementType == nil || limit.placementType == placementType) && limit.groupIDs.contains(placementGroup)
        }
        return (matching.first { $0.feature == feature } ?? matching.first { $0.feature == nil })?.maxCount
    }

    private func specsByID(isVideo: Bool) -> [String: AssetLibrarySpec] {
        let media: AssetLibraryMedia = isVideo ? .video : .image
        return Dictionary(specs.filter { $0.media == media }.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
