//
//  CaptionBook.swift
//  AppLocalizer
//

import Foundation

/// Every caption of an app, by locale code and slot index. Stored as
/// `{ "de-DE": [caption, null, …] }`, so a missing caption is a `null`.
struct CaptionBook: Codable, Hashable, Sendable {
    private(set) var captionsByLocale: [String: [ScreenshotCaption?]]

    init(_ captionsByLocale: [String: [ScreenshotCaption?]] = [:]) {
        self.captionsByLocale = captionsByLocale
    }

    init(from decoder: any Decoder) throws {
        captionsByLocale = try decoder.singleValueContainer().decode([String: [ScreenshotCaption?]].self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(captionsByLocale)
    }

    /// The caption for `locale` and `slot`, or nil when there's none or it's
    /// empty.
    func caption(locale: String, slot: Int) -> ScreenshotCaption? {
        guard let captions = captionsByLocale[locale], captions.indices.contains(slot),
              let caption = captions[slot], !caption.isEmpty else { return nil }
        return caption
    }

    mutating func setCaption(_ caption: ScreenshotCaption?, locale: String, slot: Int) {
        var captions = captionsByLocale[locale] ?? []
        if captions.count <= slot { captions += Array(repeating: nil, count: slot + 1 - captions.count) }
        captions[slot] = caption
        captionsByLocale[locale] = captions
    }

    /// Every language's captions on the slots their screens moved to; the
    /// captions of a screen the set no longer has are dropped.
    mutating func move(_ move: CaptionSlotMove) {
        captionsByLocale = captionsByLocale.mapValues { captions in
            move.sources.map { source in source.flatMap { captions.indices.contains($0) ? captions[$0] : nil } }
        }
    }

    /// How many of `slotCount` slots have a caption in `locale`.
    func count(locale: String, slotCount: Int) -> Int {
        (0..<slotCount).count { caption(locale: locale, slot: $0) != nil }
    }

    /// The locales with at least one caption.
    var locales: [String] {
        captionsByLocale.keys.filter { code in captionsByLocale[code]?.contains { $0.map { !$0.isEmpty } ?? false } ?? false }.sorted()
    }
}
