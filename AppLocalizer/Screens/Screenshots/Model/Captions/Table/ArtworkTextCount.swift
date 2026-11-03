//
//  ArtworkTextCount.swift
//  AppLocalizer
//

import Foundation

/// How long a placement's text is against its role's limit: words, or
/// characters in Chinese, Japanese and Korean, which don't space words;
/// and the search headline's characters in any language.
struct ArtworkTextCount: Hashable, Sendable {
    var words: Int
    var characters: Int
    var countsCharacters: Bool
    var role: ArtworkTextRole

    init(_ text: String, role: ArtworkTextRole, locale: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.role = role
        characters = trimmed.count
        countsCharacters = ["ja", "zh", "ko"].contains(String(locale.prefix(2)))
        words = trimmed.split(whereSeparator: \.isWhitespace).count
    }

    /// Over the role's words (or about 2 characters a word in CJK), or a
    /// search headline over about 32 characters.
    var isTooLong: Bool {
        if role == .search, characters > ArtworkTextRole.maximumSearchCharacters { return true }
        return countsCharacters ? characters > role.maximumWords * 2 : words > role.maximumWords
    }

    /// "4 words", "12 characters".
    var title: String {
        if countsCharacters { return characters == 1 ? String(localized: "1 character") : String(localized: "\(characters) characters") }
        return words == 1 ? String(localized: "1 word") : String(localized: "\(words) words")
    }
}
