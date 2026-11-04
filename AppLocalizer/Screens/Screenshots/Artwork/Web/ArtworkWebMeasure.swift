//
//  ArtworkWebMeasure.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// What a rendered Claude Design page holds, read from the page itself:
/// where each `data-al` element landed and how its text fits, its
/// animations, and how big the page grew. Geometry is in canvas pixels
/// (one CSS pixel each).
struct ArtworkWebMeasure: Codable, Hashable, Sendable {
    /// One marked element as rendered.
    struct Element: Codable, Hashable, Sendable {
        /// `ArtworkWebMarker`'s raw value.
        var marker: String
        /// A capture's `data-slot`, from 1.
        var slot: Int?
        /// The box it covers as turned: for text, the text itself.
        var x: Double
        var y: Double
        var width: Double
        var height: Double
        var text: String?
        /// Its ink, as CSS gives it ("rgb(255, 243, 224)").
        var color: String?
        /// The first family it's set in, and its size once fitted.
        var font: String?
        var fontSize: Double?
        /// The share of its full size it's set at; 1 unless `data-al-fit`
        /// shrank it.
        var fitScale: Double?
        /// The text stays inside its box (or its lines).
        var fits: Bool
        var isVisible: Bool
        /// An image that loaded.
        var isLoaded: Bool?
        /// A `data-al="text"`'s versions: the `lang` of each, as written.
        var languages: [String]?
        /// A `data-al="text"`'s words in the primary language, spaces
        /// collapsed: its key in `ArtworkTextBook.phrases`.
        var source: String?
        /// The versions a `data-al="text"` carries itself, by `lang` (pages
        /// from before AppLocalizer translated them).
        var versions: [String: String]?
        /// A `data-al="text"` without its words in this language: one with
        /// versions shows nothing, one without its primary-language words.
        var isMissingLanguage: Bool?

        var frame: CGRect { CGRect(x: x, y: y, width: width, height: height) }

        var kind: ArtworkWebMarker? { ArtworkWebMarker(rawValue: marker) }

        var hasText: Bool { !(text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// One CSS animation or transition.
    struct Motion: Codable, Hashable, Sendable {
        /// How long until it looks the same again, in milliseconds: its
        /// duration, twice that when it alternates.
        var period: Double
        var isInfinite: Bool
        /// When it ends, in milliseconds, for one that doesn't repeat.
        var end: Double
    }

    var elements: [Element]
    var motions: [Motion] = []
    /// SVG animations (`<animate>`…), stepped with the page.
    var hasSVGAnimation = false
    /// Words the page wrote outside every `data-al` element, the same in
    /// every language (a few, cut at 80 characters).
    var strayText: [String]?
    /// How far the page reaches, in pixels: past the canvas is cut off.
    var contentWidth: Double
    var contentHeight: Double

    func elements(_ marker: ArtworkWebMarker) -> [Element] {
        elements.filter { $0.marker == marker.rawValue }
    }

    var headline: Element? { elements(.headline).first }

    /// The page's own words (`data-al="text"`) that show.
    var texts: [Element] { elements(.text).filter { $0.isVisible && $0.hasText } }

    /// The page's phrases (`data-al="text"`) by their words in the primary
    /// language, each once, in page order.
    var phraseSources: [String] {
        var seen: Set<String> = []
        return elements(.text).compactMap { element in
            let source = ArtworkTextBook.phraseKey(element.source ?? element.text ?? "")
            return !source.isEmpty && seen.insert(source).inserted ? source : nil
        }
    }

    /// The phrases without their words in some of `locales`, each with the
    /// locales it lacks: not the primary language (`primary`, whose words
    /// the page has), not in `book`, and not among the page's own versions.
    func phrasesMissing(_ locales: [String], primary: String, book: ArtworkTextBook) -> [(text: String, locales: [String])] {
        var seen: Set<String> = []
        return elements(.text).compactMap { element in
            let source = ArtworkTextBook.phraseKey(element.source ?? element.text ?? "")
            guard !source.isEmpty, seen.insert(source).inserted else { return nil }
            let languages = element.languages ?? []
            let missing = locales.filter { code in
                code != primary && book.phrase(source, locale: code) == nil && !ArtworkWebTextVersions.covers(languages, locale: code)
            }
            return missing.isEmpty ? nil : (source, missing)
        }
    }

    /// Every headline element fits (an empty one does).
    var headlineFits: Bool { elements(.headline).allSatisfy(\.fits) }

    /// Something on the page moves.
    var moves: Bool { hasSVGAnimation || !motions.isEmpty }

    /// Motion that may not land back on the first frame when the loop
    /// ends: a repeating one whose cycle doesn't divide the loop, or one
    /// that plays once and stops before the end or runs past it.
    func motionsThatMayJump(loopSeconds: Double) -> [Motion] {
        let loop = loopSeconds * 1000
        return motions.filter { motion in
            guard motion.isInfinite else { return motion.end > 0 && abs(motion.end - loop) > 1 }
            guard motion.period > 0 else { return false }
            let cycles = loop / motion.period
            return abs(cycles - cycles.rounded()) > 0.001
        }
    }
}
