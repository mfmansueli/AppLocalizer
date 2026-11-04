//
//  ArtworkTextRole.swift
//  AppLocalizer
//

import Foundation

/// The two placements' own text. The search results image answers what
/// people searched for, so its headline states the app's purpose in 3–5
/// words; the product page header carries one feeling or outcome, with at
/// most about 3 words or none. One 16:9 image for both carries the search
/// headline.
enum ArtworkTextRole: String, Codable, Hashable, Sendable, CaseIterable {
    case search
    case header

    /// "Search results" or "Header": the Captions column.
    var title: String {
        switch self {
        case .search: String(localized: "Search results")
        case .header: String(localized: "Header")
        }
    }

    /// The most words it should have; more is a warning, not an error.
    var maximumWords: Int {
        switch self {
        case .search: 5
        case .header: 3
        }
    }

    /// The most characters a search headline should have in any language.
    static let maximumSearchCharacters = 32

    /// The header's line is optional and empty by default; every language
    /// needs a search headline.
    var isOptional: Bool { self == .header }

    /// What it's for, for the editor and the assistant.
    var guidance: String {
        switch self {
        case .search:
            String(localized: """
            3–5 words that answer the search: people comparing apps see a small card, so state the obvious. Start from \
            this language’s keywords and subtitle.
            """)
        case .header:
            String(localized: "Optional: at most about 3 words for one feeling or outcome, or none. The first screenshot below delivers on it.")
        }
    }

    /// The artwork the text goes on: the search image, or the one 16:9
    /// image for both; the header image.
    func kind(for size: AutopilotArtworkSize) -> AutopilotArtworkKind {
        switch (self, size) {
        case (_, .wide): .wide
        case (.search, _): .search
        case (.header, _): .header
        }
    }

    /// The text an artwork carries: the header's line on the header, the
    /// search headline on the search image and on one 16:9 image for both.
    static func role(for kind: AutopilotArtworkKind) -> ArtworkTextRole {
        kind == .header ? .header : .search
    }

    /// The roles a size has text for: one 16:9 image carries only the
    /// search headline, the header alone only its line.
    static func roles(for size: AutopilotArtworkSize) -> [ArtworkTextRole] {
        size.roles
    }
}
