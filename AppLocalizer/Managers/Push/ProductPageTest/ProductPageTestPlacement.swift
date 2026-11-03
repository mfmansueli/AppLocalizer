//
//  ProductPageTestPlacement.swift
//  AppLocalizer
//

import Foundation

/// What a Product Page Optimization test changes: the product page header
/// or the search results image. A test changes one of them.
enum ProductPageTestPlacement: String, Codable, Hashable, Sendable, CaseIterable {
    case header
    case searchResults

    var placementType: String {
        switch self {
        case .header: ExtrasPushKind.productPageHeader
        case .searchResults: ExtrasPushKind.searchResults
        }
    }

    /// "Header", "Search results": file names and rows.
    var title: String {
        switch self {
        case .header: String(localized: "Header")
        case .searchResults: String(localized: "Search results")
        }
    }

    /// The treatment's tab in App Store Connect.
    var tabTitle: String {
        switch self {
        case .header: String(localized: "Header")
        case .searchResults: String(localized: "Search Results")
        }
    }

    /// The placements artwork of `kind` can be tested in: the 16:9 image
    /// is both, and the person picks one.
    static func placements(for kind: AutopilotArtworkKind) -> [ProductPageTestPlacement] {
        switch kind {
        case .header: [.header]
        case .search: [.searchResults]
        case .wide: [.header, .searchResults]
        }
    }
}
