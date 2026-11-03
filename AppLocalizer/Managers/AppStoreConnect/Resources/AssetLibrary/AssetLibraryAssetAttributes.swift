//
//  AssetLibraryAssetAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appAssetLibraryImages` or `appAssetLibraryVideos` resource's
/// attributes, read leniently: each state has its own attribute shape, so
/// every field is optional and one that doesn't decode is left out.
struct AssetLibraryAssetAttributes: Decodable, Sendable {
    var fileName: String?
    var referenceName: String?
    var state: String?
    var stateDetails: [AssetLibraryStateDetail] = []
    /// Set on a reservation: one operation per part of the file.
    var uploadOperations: [ScreenshotUploadOperation]?

    private enum CodingKeys: String, CodingKey {
        case fileName, referenceName, state, stateDetails, uploadOperations
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileName = try? container.decodeIfPresent(String.self, forKey: .fileName)
        referenceName = try? container.decodeIfPresent(String.self, forKey: .referenceName)
        state = try? container.decodeIfPresent(String.self, forKey: .state)
        stateDetails = AssetLibraryStateDetail.list(in: container, forKey: .stateDetails)
        uploadOperations = try? container.decodeIfPresent([ScreenshotUploadOperation].self, forKey: .uploadOperations)
    }

    var status: AssetLibraryAssetStatus {
        AssetLibraryAssetStatus(state: state, details: stateDetails)
    }
}
