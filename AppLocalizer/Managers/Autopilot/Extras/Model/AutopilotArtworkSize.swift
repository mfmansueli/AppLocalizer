//
//  AutopilotArtworkSize.swift
//  AppLocalizer
//

import Foundation

/// The artwork Apple takes for the product page header and search
/// results: a 21:9 header and a 3:2 search image, or one 16:9 image for
/// both places.
enum AutopilotArtworkSize: String, Codable, CaseIterable, Hashable, Sendable {
    case headerAndSearch
    case wide

    /// What's made per language.
    var kinds: [AutopilotArtworkKind] {
        switch self {
        case .headerAndSearch: [.header, .search]
        case .wide: [.wide]
        }
    }

    /// The plan's segmented control.
    var title: String {
        switch self {
        case .headerAndSearch: String(localized: "Header 21:9 and search 3:2")
        case .wide: String(localized: "One 16:9 image for both")
        }
    }

    /// "header and search artwork", in the plan's footer.
    var madeTitle: String {
        switch self {
        case .headerAndSearch: String(localized: "header and search artwork")
        case .wide: String(localized: "one 16:9 header and search image")
        }
    }

    /// "21:9 and 3:2", "16:9 · 5244 × 2950".
    var shortTitle: String {
        switch self {
        case .headerAndSearch: String(localized: "21:9 and 3:2")
        case .wide: "16:9 · \(AutopilotArtworkKind.wide.pixelSize.title)"
        }
    }
}
