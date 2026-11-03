//
//  ArtworkTextCell.swift
//  AppLocalizer
//

import Foundation

/// One Search results or Header cell in Captions: the text, its fit on
/// the direction's artwork, and its words against the role's limit.
struct ArtworkTextCell: Hashable, Sendable, Identifiable {
    var key: ArtworkTextKey
    var text: ScreenshotCaption?
    /// Nil without a look to measure on.
    var fit: CaptionFit?
    var isPrimary: Bool

    var id: ArtworkTextKey { key }

    var role: ArtworkTextRole { key.role }

    /// A language without a search headline; an empty header is fine.
    var isMissing: Bool { text == nil && !role.isOptional }

    /// "Write headline", "Missing", or "No line" for an empty header.
    var emptyTitle: String {
        if role.isOptional { return String(localized: "No line") }
        return isPrimary ? String(localized: "Write headline") : String(localized: "Missing")
    }

    var isOverflowing: Bool { fit?.tone == .overflows }

    var isMachineTranslated: Bool { text?.provenance.isMachineTranslated == true }

    var assistant: String? {
        if case let .assistant(client, _)? = text?.provenance { return client }
        return nil
    }

    /// The words, CJK by characters: Apple's search card is small.
    var count: ArtworkTextCount? {
        guard let text else { return nil }
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
        let place = "\(localeName) \(role.title.lowercased())"
        guard let text else { return "\(place): \(emptyTitle)" }
        return "\(place): \(text.headline), \(fitLabel)"
    }
}
