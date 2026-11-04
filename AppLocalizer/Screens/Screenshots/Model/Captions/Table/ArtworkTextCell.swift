//
//  ArtworkTextCell.swift
//  AppLocalizer
//

import Foundation

/// One Search results or Header cell in Captions: the text, its fit on
/// the direction's artwork, and its words against the role's limit. With
/// `phraseIndex`, one of the pages' phrases: in the primary language the
/// page's own words (or the person's change to them), elsewhere their
/// translation.
struct ArtworkTextCell: Hashable, Sendable, Identifiable {
    var key: ArtworkTextKey
    var text: ScreenshotCaption?
    /// Nil without a look to measure on.
    var fit: CaptionFit?
    var isPrimary: Bool
    /// A phrase's column among the phrases, from 0.
    var phraseIndex: Int?

    var id: ArtworkTextKey { key }

    var role: ArtworkTextRole { key.role }

    var isPhrase: Bool { key.phrase != nil }

    /// "Search results", "Header", or "Phrase 2".
    var columnTitle: String { phraseIndex.map(Self.phraseTitle) ?? role.title }

    static func phraseTitle(_ index: Int) -> String {
        String(localized: "Phrase \(index + 1)")
    }

    /// The end of the cell's accessibility identifier: the role, or
    /// "text.1" for the second phrase.
    var identifierSuffix: String { phraseIndex.map { "text.\($0)" } ?? role.rawValue }

    /// A language without a search headline or a phrase's words; an empty
    /// header is fine.
    var isMissing: Bool { text == nil && (isPhrase || !role.isOptional) }

    /// "Write headline", "Missing", or "No line" for an empty header.
    var emptyTitle: String {
        if isPhrase { return String(localized: "Missing") }
        if role.isOptional { return String(localized: "No line") }
        return isPrimary ? String(localized: "Write headline") : String(localized: "Missing")
    }

    var isOverflowing: Bool { fit?.tone == .overflows }

    var isMachineTranslated: Bool { text?.provenance.isMachineTranslated == true }

    var assistant: String? {
        if case let .assistant(client, _)? = text?.provenance { return client }
        return nil
    }

    /// The words, CJK by characters: Apple's search card is small. A
    /// phrase has no limit of its own; its box is its limit.
    var count: ArtworkTextCount? {
        guard let text, !isPhrase else { return nil }
        return ArtworkTextCount(text.headline, role: role, locale: key.locale)
    }

    var needsAttention: Bool { isMissing || isOverflowing || isMachineTranslated || count?.isTooLong == true }

    /// "Fits at 211 px · 4 words", or "No look yet".
    var fitLabel: String {
        let fitText = fit.map { ArtworkTextCell.label($0) } ?? String(localized: "No look yet")
        guard let count else { return fitText }
        return "\(fitText) · \(count.title)"
    }

    /// The fit in pixels: artwork sizes aren't in u.
    static func label(_ fit: CaptionFit) -> String {
        let size = Int(fit.size.rounded())
        switch fit.tone {
        case .empty: return String(localized: "No text")
        case .fits: return String(localized: "Fits at \(size) px")
        case .shrinks: return String(localized: "Shrinks to \(size) px")
        case .overflows: return String(localized: "Too long at \(size) px")
        }
    }

    /// For VoiceOver: "German search results: Tagebuch für jeden Tag, fits at 211 px".
    func accessibilityText(localeName: String) -> String {
        let place = "\(localeName) \(columnTitle.lowercased())"
        guard let text else { return "\(place): \(emptyTitle)" }
        return "\(place): \(text.headline), \(fitLabel)"
    }
}
