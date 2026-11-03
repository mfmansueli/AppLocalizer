//
//  AutopilotArtworkKind.swift
//  AppLocalizer
//

import Foundation

/// One artwork image Apple places on the App Store, at the size Autopilot
/// makes it (Apple's "Creative assets specifications"): the product page
/// header (21:9), the search results image (3:2, 1920 × 1280 up to 3840 ×
/// 2560), or one 16:9 image for both. PNG, no alpha channel.
enum AutopilotArtworkKind: String, Codable, CaseIterable, Hashable, Sendable {
    case header
    case search
    case wide

    var pixelSize: PixelSize {
        switch self {
        case .header: PixelSize(width: 3840, height: 1646)
        case .search: PixelSize(width: 3840, height: 2560)
        case .wide: PixelSize(width: 5244, height: 2950)
        }
    }

    /// "21:9".
    var ratioTitle: String {
        switch self {
        case .header: "21:9"
        case .search: "3:2"
        case .wide: "16:9"
        }
    }

    /// "Header", "Search results", "Header and search".
    var title: String {
        switch self {
        case .header: String(localized: "Header")
        case .search: String(localized: "Search results")
        case .wide: String(localized: "Header and search")
        }
    }

    /// The places App Store Connect's Asset Library puts it.
    var placementTypes: [String] {
        switch self {
        case .header: [Self.headerPlacement]
        case .search: [Self.searchPlacement]
        case .wide: [Self.headerPlacement, Self.searchPlacement]
        }
    }

    static let headerPlacement = "PRODUCT_PAGE_HEADER_ASSET"
    static let searchPlacement = "APP_STORE_SEARCH_RESULTS_ASSET"

    /// The header's own image, or the 16:9 one that is also the header.
    var isHeader: Bool { self != .search }

    /// The search results image, or the 16:9 one that is also it.
    var isSearch: Bool { self != .header }
}
