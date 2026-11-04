//
//  ArtworkTextBook.swift
//  AppLocalizer
//

import Foundation

/// The header's line and the search results headline per language, apart
/// from the screenshots' captions, and the phrases Claude Design wrote on
/// the header and search pages, translated here like captions. Each keeps
/// its provenance like a caption (written, machine-translated, edited,
/// reviewed).
struct ArtworkTextBook: Codable, Hashable, Sendable {
    var search: [String: ScreenshotCaption] = [:]
    var header: [String: ScreenshotCaption] = [:]
    /// The pages' own phrases (`data-al="text"`) per language, by the
    /// words as the page writes them in the primary language
    /// (`phraseKey`). In the primary language one is there only when the
    /// person changed the page's words. Nil in documents from before.
    var phrases: [String: [String: ScreenshotCaption]]?

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

    var isEmpty: Bool { search.isEmpty && header.isEmpty && (phrases ?? [:]).isEmpty }

    // MARK: - The pages' phrases

    /// A phrase's key: its words with their spaces collapsed, as the page
    /// reads them (`ArtworkWebScript`).
    static func phraseKey(_ words: String) -> String {
        words.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// The phrase `source` in `locale`; nil when it has none there, or it's
    /// empty.
    func phrase(_ source: String, locale: String) -> ScreenshotCaption? {
        phrases?[Self.phraseKey(source)]?[locale].flatMap { $0.isEmpty ? nil : $0 }
    }

    mutating func setPhrase(_ text: ScreenshotCaption?, source: String, locale: String) {
        let key = Self.phraseKey(source)
        guard !key.isEmpty else { return }
        var all = phrases ?? [:]
        var versions = all[key] ?? [:]
        versions[locale] = text.flatMap { $0.isEmpty ? nil : $0 }
        all[key] = versions.isEmpty ? nil : versions
        phrases = all.isEmpty ? nil : all
    }

    /// `versions` (phrase → locale → words) laid over the book's, from
    /// `provenance`; blank words are left out.
    mutating func setPhrases(_ versions: [String: [String: String]], provenance: CaptionProvenance) {
        for (source, words) in versions {
            for (locale, text) in words {
                let text = Self.phraseKey(text)
                guard !text.isEmpty else { continue }
                setPhrase(ScreenshotCaption(headline: text, subhead: nil, provenance: provenance), source: source, locale: locale)
            }
        }
    }

    /// What a page writes for its phrases in `locale`: each phrase's words
    /// there, by its key. A phrase without them keeps the page's own words
    /// in the primary language, and is missing in the others.
    func phraseTexts(locale: String) -> [String: String] {
        (phrases ?? [:]).compactMapValues { versions in
            versions[locale].flatMap { $0.isEmpty ? nil : $0.headline }
        }
    }
}
