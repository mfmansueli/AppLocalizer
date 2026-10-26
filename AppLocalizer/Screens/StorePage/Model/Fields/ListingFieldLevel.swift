//
//  ListingFieldLevel.swift
//  AppLocalizer
//

import Foundation

/// Where a field lives in App Store Connect: on the app (shared by every
/// version) or on one version.
enum ListingFieldLevel: Hashable, Sendable {
    case app
    case version

    /// The coverage grid's group header: "App information · all versions"
    /// or "Version 1.4".
    func groupTitle(version: String) -> String {
        switch self {
        case .app: String(localized: "App information · all versions")
        case .version: String(localized: "Version \(version)")
        }
    }

    /// The editor's badge next to a field: "App information" or "Version 1.4".
    func badgeTitle(version: String) -> String {
        switch self {
        case .app: String(localized: "App information")
        case .version: String(localized: "Version \(version)")
        }
    }
}
