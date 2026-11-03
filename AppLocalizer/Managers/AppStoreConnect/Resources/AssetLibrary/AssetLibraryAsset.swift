//
//  AssetLibraryAsset.swift
//  AppLocalizer
//

import Foundation

/// One asset in an app's library, by ID and kind: what a commit, a state
/// check and a placement refer to.
struct AssetLibraryAsset: Codable, Hashable, Sendable {
    var id: String
    var media: AssetLibraryMedia
}
