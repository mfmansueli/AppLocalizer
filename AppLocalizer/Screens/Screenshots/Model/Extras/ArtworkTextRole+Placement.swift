//
//  ArtworkTextRole+Placement.swift
//  AppLocalizer
//

import Foundation

/// The jobs an image does on the App Store, for its checks: the product
/// page's header, the search results card, or both for the one 16:9 image
/// (which carries the search headline as its text).
extension ArtworkTextRole {
    static func placementRoles(for kind: AutopilotArtworkKind) -> [ArtworkTextRole] {
        switch kind {
        case .header: [.header]
        case .search: [.search]
        case .wide: [.header, .search]
        }
    }

    /// "header", "search image" or "header and search image", for "German
    /// header: …".
    static func placementTitle(of roles: [ArtworkTextRole]) -> String {
        switch (roles.contains(.header), roles.contains(.search)) {
        case (true, true): String(localized: "header and search image")
        case (true, false): String(localized: "header")
        default: String(localized: "search image")
        }
    }
}
