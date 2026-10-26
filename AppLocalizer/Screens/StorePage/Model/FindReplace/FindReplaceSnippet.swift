//
//  FindReplaceSnippet.swift
//  AppLocalizer
//

import Foundation

/// One line of context around a match for the preview list:
/// "…ID, synced with iCloud ", "Lumen Plus", " unlocks unlimited photos, the…".
/// Line breaks read as spaces.
struct FindReplaceSnippet: Hashable, Sendable {
    let prefix: String
    /// The highlighted part: the match, or the replacement in an "after" snippet.
    let match: String
    let suffix: String

    static let charactersBefore = 24
    static let charactersAfter = 30

    init(text: String, range: Range<String.Index>, highlighted: String? = nil) {
        let start = text.index(range.lowerBound, offsetBy: -Self.charactersBefore, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: Self.charactersAfter, limitedBy: text.endIndex) ?? text.endIndex
        let before = Self.oneLine(text[start..<range.lowerBound])
        let after = Self.oneLine(text[range.upperBound..<end])
        prefix = start > text.startIndex ? "…" + before : before
        match = Self.oneLine(highlighted.map { Substring($0) } ?? text[range])
        suffix = end < text.endIndex ? after + "…" : after
    }

    var text: String { prefix + match + suffix }

    /// Line breaks, and blank lines between paragraphs, become one space.
    private static func oneLine(_ text: Substring) -> String {
        var result = ""
        var pendingBreak = false
        for character in text {
            if character.isNewline {
                pendingBreak = true
                continue
            }
            if pendingBreak, character != " ", result.last != " " { result.append(" ") }
            pendingBreak = false
            result.append(character)
        }
        if pendingBreak, result.last != " " { result.append(" ") }
        return result
    }
}
