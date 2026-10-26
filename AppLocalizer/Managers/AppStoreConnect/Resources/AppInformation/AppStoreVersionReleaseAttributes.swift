//
//  AppStoreVersionReleaseAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `appStoreVersions` attributes App Information reads: what the
/// version picker needs, plus copyright and release. `releaseType` is
/// `MANUAL`, `AFTER_APPROVAL` or `SCHEDULED`; `earliestReleaseDate` is ISO
/// 8601 and only matters when scheduled.
struct AppStoreVersionReleaseAttributes: Decodable, Sendable {
    var versionString: String
    var platform: String?
    var appStoreState: String?
    var appVersionState: String?
    var createdDate: String?
    var copyright: String?
    var releaseType: String?
    var earliestReleaseDate: String?

    /// The newer state when Apple sends it, else the older one.
    var state: String? { appVersionState ?? appStoreState }
}
