//
//  ArtworkWebRequest.swift
//  AppLocalizer
//

import Foundation

/// One Claude Design page to render in one language: the HTML, the canvas
/// it's for, and what AppLocalizer fills in.
struct ArtworkWebRequest: Sendable {
    var html: String
    var kind: AutopilotArtworkKind
    /// The App Store locale, e.g. "de-DE": the page's `lang`.
    var locale: String
    var isRightToLeft: Bool
    /// The placement's own text in this language (`data-al="headline"`).
    var headline: String
    var appName: String
    /// Each slot's picked capture (0-based slot, `data-slot` is 1-based),
    /// encoded as PNG.
    var captures: [Int: Data] = [:]
    var icon: Data?
    /// Where in the loop, in seconds: 0 is the poster.
    var time: Double = 0
    /// How wide the image comes back, in pixels; nil is the canvas's width.
    var pixelWidth: Int?
    /// The run's primary language: a page's phrases are written in it.
    /// Nil takes every phrase as written for this language.
    var primaryLocale: String?
    /// The page's phrases (`data-al="text"`) in this language, by their
    /// words in the primary language (`ArtworkTextBook.phraseTexts`).
    var phrases: [String: String] = [:]

    var pixelSize: PixelSize { kind.pixelSize }

    /// `pixelWidth`, at most the canvas's width.
    var outputWidth: Int { min(pixelWidth ?? pixelSize.width, pixelSize.width) }

    var outputHeight: Int {
        Int((Double(pixelSize.height) * Double(outputWidth) / Double(pixelSize.width)).rounded())
    }
}
