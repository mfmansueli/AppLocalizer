//
//  ArtworkTextBook.swift
//  AppLocalizer
//

import Foundation

/// The header's line and the search results headline per language, apart
/// from the screenshots' captions. Each keeps its provenance like a
/// caption (written, machine-translated, edited, reviewed).
struct ArtworkTextBook: Codable, Hashable, Sendable {
    var search: [String: ScreenshotCaption] = [:]
    var header: [String: ScreenshotCaption] = [:]

    /// The text for `role` in `locale`; nil when there's none or it's empty.
    func text(_ role: ArtworkTextRole, locale: String) -> ScreenshotCaption? {
        let text = switch role {
        case .search: search[locale]
        case .header: header[locale]
        }
        return text.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// The headline drawn: empty when there's none.
    func headline(_ role: ArtworkTextRole, locale: String) -> String {
        text(role, locale: locale)?.headline ?? ""
    }

    mutating func set(_ text: ScreenshotCaption?, role: ArtworkTextRole, locale: String) {
        let kept = text.flatMap { $0.isEmpty ? nil : $0 }
        switch role {
        case .search: search[locale] = kept
        case .header: header[locale] = kept
        }
    }

    var isEmpty: Bool { search.isEmpty && header.isEmpty }
}
