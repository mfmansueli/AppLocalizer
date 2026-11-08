//
//  ScreenshotCaption.swift
//  AppLocalizer
//

import Foundation

/// The text on one locale × slot: a headline, on hero slots an optional
/// subhead, and, where the template sets a kicker style, an optional
/// kicker line over the headline. The same caption goes on every display
/// type.
struct ScreenshotCaption: Codable, Hashable, Sendable {
    var headline: String
    var subhead: String?
    /// The short topic line over the headline (`caption.kicker`).
    var kicker: String?
    var provenance: CaptionProvenance

    init(headline: String, subhead: String? = nil, kicker: String? = nil, provenance: CaptionProvenance = .reviewed) {
        self.headline = headline
        self.subhead = subhead
        self.kicker = kicker
        self.provenance = provenance
    }

    /// Nothing to draw: the cell shows "No caption" instead.
    var isEmpty: Bool {
        headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The subhead when there is one worth drawing.
    var visibleSubhead: String? {
        guard let subhead, !subhead.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return subhead
    }

    /// The kicker when there is one worth drawing.
    var visibleKicker: String? {
        guard let kicker, !kicker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return kicker
    }

    /// What the render depends on: the text, not who wrote it. A caption
    /// without a kicker keeps the key it had before kickers.
    var renderText: String {
        let base = headline + "\u{1F}" + (visibleSubhead ?? "")
        return visibleKicker.map { base + "\u{1F}" + $0 } ?? base
    }
}
