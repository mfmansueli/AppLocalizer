//
//  RetentionPlacementGroup.swift
//  AppLocalizer
//

import Foundation

/// The placement group a retention image of one size goes in, read from
/// Apple's reference data (`RETENTION_MESSAGE_ASSET`) rather than
/// hard-coded.
struct RetentionPlacementGroup: Hashable, Sendable {
    var width: Int
    var height: Int

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// From the placeholder's `3840x1000`.
    init(size: String) {
        let parts = size.split(separator: "x").compactMap { Int($0) }
        width = parts.first ?? 0
        height = parts.count > 1 ? parts[1] : 0
    }

    func groupID(in refData: AssetLibraryRefData) -> String? {
        refData.placementGroups(for: RetentionRequests.placementType, pixelSize: PixelSize(width: width, height: height), isVideo: false).first
    }

    /// The group, and the asset category the reference data says
    /// retention images are reserved under (nil when it doesn't say).
    @MainActor
    func resolve(via transport: any PushTransport, note: (AppStoreConnectRateLimit?) -> Void) async throws -> (groupID: String, category: String?) {
        let response = try await transport.fetch(AssetLibraryRequests.refDataPath)
        note(response.rateLimit)
        let refData = try AssetLibraryRefData(json: response.data)
        guard let id = groupID(in: refData) else { throw RetentionPushError.noPlacementGroup(width: width, height: height) }
        return (id, Self.assetCategory(in: response.data))
    }

    /// `placementTypes[RETENTION_MESSAGE_ASSET].acceptsAssetCategories`'s
    /// first, from the reference data's JSON.
    static func assetCategory(in json: Data) -> String? {
        let object = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any]
        let data = (object?["data"] as? [[String: Any]])?.first ?? object?["data"] as? [String: Any]
        let attributes = data?["attributes"] as? [String: Any]
        let types = attributes?["placementTypes"] as? [[String: Any]] ?? []
        let retention = types.first { $0["placementTypeId"] as? String == RetentionRequests.placementType }
        return (retention?["acceptsAssetCategories"] as? [String])?.first
    }
}
