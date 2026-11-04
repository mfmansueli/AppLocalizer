//
//  AutopilotArtworkSize.swift
//  AppLocalizer
//

import Foundation

/// The artwork Apple takes for the product page header and search
/// results: a 21:9 header and a 3:2 search image, only one of them (the
/// other place keeps what it shows), or one 16:9 image for both places.
enum AutopilotArtworkSize: String, Codable, CaseIterable, Hashable, Sendable {
    case headerAndSearch
    case headerOnly
    case searchOnly
    case wide

    /// What's made per language.
    var kinds: [AutopilotArtworkKind] {
        switch self {
        case .headerAndSearch: [.header, .search]
        case .headerOnly: [.header]
        case .searchOnly: [.search]
        case .wide: [.wide]
        }
    }

    /// The image the product page header shows; nil when the run leaves
    /// the header as it is.
    var headerKind: AutopilotArtworkKind? {
        switch self {
        case .headerAndSearch, .headerOnly: .header
        case .searchOnly: nil
        case .wide: .wide
        }
    }

    /// The image search results show; nil when the run leaves them as
    /// they are.
    var searchKind: AutopilotArtworkKind? {
        switch self {
        case .headerAndSearch, .searchOnly: .search
        case .headerOnly: nil
        case .wide: .wide
        }
    }

    /// The place the run leaves as it is, keeping its artwork from before;
    /// nil when it makes both.
    var keptKind: AutopilotArtworkKind? {
        switch self {
        case .headerOnly: .search
        case .searchOnly: .header
        case .headerAndSearch, .wide: nil
        }
    }

    /// The placements' texts it carries: one 16:9 image has only the
    /// search headline.
    var roles: [ArtworkTextRole] {
        switch self {
        case .headerAndSearch: [.search, .header]
        case .headerOnly: [.header]
        case .searchOnly, .wide: [.search]
        }
    }

    /// Apple takes motion at 21:9 and 3:2, not 16:9.
    var allowsMotion: Bool { self != .wide }

    /// The plan's menu.
    var title: String {
        switch self {
        case .headerAndSearch: String(localized: "Header 21:9 and search 3:2")
        case .headerOnly: String(localized: "Header 21:9 only")
        case .searchOnly: String(localized: "Search results 3:2 only")
        case .wide: String(localized: "One 16:9 image for both")
        }
    }

    /// "Header and search", "Header", "Search results", "Header and
    /// search · 16:9": Localize's row and Ready's note.
    var placeTitle: String {
        switch self {
        case .headerAndSearch: String(localized: "Header and search")
        case .headerOnly: String(localized: "Header")
        case .searchOnly: String(localized: "Search results")
        case .wide: String(localized: "Header and search · 16:9")
        }
    }

    /// "Header and search artwork", in the log.
    var artworkTitle: String {
        switch self {
        case .headerAndSearch: String(localized: "Header and search artwork")
        case .headerOnly: String(localized: "Header artwork")
        case .searchOnly: String(localized: "Search results artwork")
        case .wide: String(localized: "Header and search image")
        }
    }

    /// "header and search artwork", in the plan's footer.
    var madeTitle: String {
        switch self {
        case .headerAndSearch: String(localized: "header and search artwork")
        case .headerOnly: String(localized: "header artwork")
        case .searchOnly: String(localized: "search results artwork")
        case .wide: String(localized: "one 16:9 header and search image")
        }
    }

    /// "moving header and search artwork", in the plan's footer.
    var movingTitle: String {
        switch self {
        case .headerAndSearch, .wide: String(localized: "moving header and search artwork")
        case .headerOnly: String(localized: "moving header artwork")
        case .searchOnly: String(localized: "moving search results artwork")
        }
    }

    /// What a direction brings when the run makes no screenshots, in
    /// Design's log.
    var directionTitle: String {
        switch self {
        case .headerAndSearch: String(localized: "header and search")
        case .headerOnly: String(localized: "header")
        case .searchOnly: String(localized: "search results image")
        case .wide: String(localized: "16:9 image")
        }
    }

    /// "21:9 and 3:2", "21:9", "3:2", "16:9 · 5244 × 2950".
    var shortTitle: String {
        switch self {
        case .headerAndSearch: String(localized: "21:9 and 3:2")
        case .headerOnly: "21:9"
        case .searchOnly: "3:2"
        case .wide: "16:9 · \(AutopilotArtworkKind.wide.pixelSize.title)"
        }
    }

    /// "3840 × 1646 and 3840 × 2560": each image's pixels.
    var pixelSizesTitle: String {
        kinds.map(\.pixelSize.title).formatted(.list(type: .and))
    }

    /// "a 21:9 header (3840 × 1646) and 3:2 search artwork (3840 × 2560)",
    /// in the brief's log line.
    var briefTitle: String {
        let header = String(localized: "a 21:9 header (\(AutopilotArtworkKind.header.pixelSize.title))")
        let search = String(localized: "3:2 search artwork (\(AutopilotArtworkKind.search.pixelSize.title))")
        switch self {
        case .headerAndSearch: return String(localized: "\(header) and \(search)")
        case .headerOnly: return header
        case .searchOnly: return String(localized: "a 3:2 search results image (\(AutopilotArtworkKind.search.pixelSize.title))")
        case .wide: return String(localized: "one 16:9 header and search image, \(AutopilotArtworkKind.wide.pixelSize.title)")
        }
    }

    /// "Header 3840 × 1646 and search 3840 × 2560", on Ready's note.
    var sizesDetail: String {
        let header = String(localized: "Header \(AutopilotArtworkKind.header.pixelSize.title)")
        let search = String(localized: "search \(AutopilotArtworkKind.search.pixelSize.title)")
        switch self {
        case .headerAndSearch: return String(localized: "\(header) and \(search)")
        case .headerOnly: return header
        case .searchOnly: return String(localized: "Search \(AutopilotArtworkKind.search.pixelSize.title)")
        case .wide: return String(localized: "One \(AutopilotArtworkKind.wide.pixelSize.title) image for both places")
        }
    }
}
