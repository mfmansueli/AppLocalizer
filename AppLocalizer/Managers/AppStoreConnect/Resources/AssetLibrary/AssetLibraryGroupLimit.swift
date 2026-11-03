//
//  AssetLibraryGroupLimit.swift
//  AppLocalizer
//

import Foundation

/// How many placements of one type these groups hold where a feature uses
/// them, e.g. 3 App Previews per device group on App Store versions.
struct AssetLibraryGroupLimit: Hashable, Sendable {
    /// Apple's `featureId`, e.g. `APP_STORE_VERSIONS`; nil when the
    /// reference data didn't say.
    var feature: String?
    var placementType: String?
    var groupIDs: [String]
    var maxCount: Int
}
