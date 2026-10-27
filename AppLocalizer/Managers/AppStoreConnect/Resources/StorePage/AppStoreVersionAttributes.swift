//
//  AppStoreVersionAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `appStoreVersions` attributes the Store Page reads. `appVersionState`
/// replaced `appStoreState`; both are read so older and newer responses work.
struct AppStoreVersionAttributes: Decodable, Sendable {
    var versionString: String
    var platform: String?
    var appStoreState: String?
    var appVersionState: String?
    /// ISO 8601, e.g. `2026-10-01T09:12:00-07:00`.
    var createdDate: String?

    /// The newer state when Apple sends it, else the older one.
    var state: String? { appVersionState ?? appStoreState }
}
