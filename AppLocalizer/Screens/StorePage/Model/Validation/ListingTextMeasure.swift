//
//  ListingTextMeasure.swift
//  AppLocalizer
//

import Foundation

/// How App Store Connect measures listing text.
///
/// - Characters are Swift `Character`s (extended grapheme clusters), so
///   "é", "日" and "👍🏽" each count once. That's what App Store Connect's own
///   counters show for listing text, including CJK and Arabic.
/// - Keywords are limited in UTF-8 bytes: ASCII costs 1, accented Latin,
///   Greek, Cyrillic, Hebrew and Arabic letters 2, CJK and Thai 3, and most
///   emoji 4.
enum ListingTextMeasure {
    static func characters(in text: String) -> Int {
        text.count
    }

    static func utf8Bytes(in text: String) -> Int {
        text.utf8.count
    }
}
