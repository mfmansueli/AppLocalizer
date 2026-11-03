//
//  ArtworkTextLength.swift
//  AppLocalizer
//

import Foundation

/// How long a line reads: its words, and its width in half-width
/// characters (a Chinese, Japanese or Korean character, or a full-width
/// form, counts two), so "about 32 characters" means the same width in
/// every script. Languages written without spaces have no words to count.
enum ArtworkTextLength {
    /// A search headline answers the search in 3 to 5 words.
    static let searchWords = 5
    /// …and about 32 half-width characters.
    static let searchWidth = 32
    /// A header line is at most about 3 words, or none.
    static let headerWords = 3
    /// …and, without spaces, about as wide as 3 short words.
    static let headerWidth = 16

    /// Chinese, Japanese, Thai, Lao, Khmer and Burmese: no spaces between
    /// words.
    static func isUnspaced(_ locale: StoreLocale) -> Bool {
        let language = locale.code.split(separator: "-").first.map(String.init)?.lowercased() ?? ""
        return ["zh", "ja", "th", "lo", "km", "my"].contains(language)
    }

    /// Words between spaces; dashes join, a lone dash or emoji isn't one.
    static func words(in text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count(where: { $0.contains { $0.isLetter || $0.isNumber } })
    }

    /// The width in half-width characters, spaces included.
    static func width(of text: String) -> Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).reduce(0) { $0 + (isWide($1) ? 2 : 1) }
    }

    /// Too long for a search headline: over 5 words (where words are
    /// spaced) or over about 32 half-width characters.
    static func isLongForSearch(_ text: String, locale: StoreLocale) -> Bool {
        (!isUnspaced(locale) && words(in: text) > searchWords) || width(of: text) > searchWidth
    }

    /// Too long for a header: over about 3 words, or as wide as more
    /// where there are no spaces.
    static func isLongForHeader(_ text: String, locale: StoreLocale) -> Bool {
        isUnspaced(locale) ? width(of: text) > headerWidth : words(in: text) > headerWords
    }

    /// East Asian wide and full-width characters.
    private static func isWide(_ character: Character) -> Bool {
        guard let value = character.unicodeScalars.first?.value else { return false }
        let ranges: [ClosedRange<UInt32>] = [
            0x1100...0x115F, 0x2E80...0x303E, 0x3041...0x33FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xA000...0xA4CF,
            0xAC00...0xD7A3, 0xF900...0xFAFF, 0xFE30...0xFE4F, 0xFF00...0xFF60, 0xFFE0...0xFFE6, 0x20000...0x3FFFD,
        ]
        return ranges.contains { $0.contains(value) }
    }
}
