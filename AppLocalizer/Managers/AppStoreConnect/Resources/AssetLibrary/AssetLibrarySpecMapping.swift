//
//  AssetLibrarySpecMapping.swift
//  AppLocalizer
//

import Foundation

/// Which specs a placement group takes for one placement type, e.g.
/// `APP_PREVIEW` in an iPhone profile group takes the 886 × 1920 and
/// 1920 × 886 video specs.
struct AssetLibrarySpecMapping: Hashable, Sendable {
    var placementType: String
    var placementGroup: String
    var specIDs: [String]
}
