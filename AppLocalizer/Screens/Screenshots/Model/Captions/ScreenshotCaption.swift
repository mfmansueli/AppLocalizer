//
//  ScreenshotCaption.swift
//  AppLocalizer
//

import Foundation

/// The text on one locale × slot: a headline and, on hero slots, an
/// optional subhead. The same caption goes on every display type.
struct ScreenshotCaption: Codable, Hashable, Sendable {
    var headline: String
    var subhead: String?
    var provenance: CaptionProvenance

    init(headline: String, subhead: String? = nil, provenance: CaptionProvenance = .reviewed) {
        self.headline = headline
        self.subhead = subhead
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

    /// What the render depends on: the text, not who wrote it.
    var renderText: String {
        headline + "\u{1F}" + (visibleSubhead ?? "")
    }
}
