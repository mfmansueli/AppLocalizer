//
//  KeywordAnalysis.swift
//  AppLocalizer
//

import Foundation

/// The keyword editor's view of a keywords string: tokens with their state,
/// the byte counter, and what "Optimize" would save.
///
/// - Tokens are split on commas and trimmed.
/// - A duplicate repeats an earlier token, ignoring case, diacritics and
///   width (`Reflexion` = `reflexión`). The first one stays plain.
/// - A token is wasted when all its words are already words of the name or
///   subtitle. Words come from the system's word breaker, which also splits
///   Japanese, Chinese and Thai.
/// - Spaces around commas are wasted bytes.
/// - `optimized` drops duplicates, wasted tokens and those spaces.
struct KeywordAnalysis: Hashable, Sendable {
    static let limit = ListingTextLimit(100, unit: .bytes)

    let keywords: String
    let tokens: [KeywordToken]
    /// Bytes of whitespace around tokens (and in empty ones).
    let wastedSpaceBytes: Int
    /// The keywords without duplicates, wasted tokens or spaces after commas.
    let optimized: String
    /// Which comma-separated part each token came from.
    private let partIndices: [Int]

    init(keywords: String, name: String, subtitle: String) {
        self.keywords = keywords
        let covered = Set(Self.words(in: "\(name) \(subtitle)"))
        var seen = Set<String>()
        var tokens: [KeywordToken] = []
        var partIndices: [Int] = []
        var wastedSpaceBytes = 0
        for (partIndex, part) in keywords.split(separator: ",", omittingEmptySubsequences: false).enumerated() {
            let text = part.trimmingCharacters(in: .whitespacesAndNewlines)
            wastedSpaceBytes += part.utf8.count - text.utf8.count
            guard !text.isEmpty else { continue }
            let folded = Self.fold(text)
            let words = Self.words(in: text)
            let state: KeywordTokenState = if seen.contains(folded) {
                .duplicate
            } else if !words.isEmpty, words.allSatisfy(covered.contains) {
                .inNameOrSubtitle
            } else {
                .useful
            }
            seen.insert(folded)
            tokens.append(KeywordToken(index: tokens.count, text: text, state: state))
            partIndices.append(partIndex)
        }
        self.tokens = tokens
        self.partIndices = partIndices
        self.wastedSpaceBytes = wastedSpaceBytes
        optimized = tokens.filter { $0.state == .useful }.map(\.text).joined(separator: ",")
    }

    var byteCount: Int { ListingTextMeasure.utf8Bytes(in: keywords) }
    var counter: ListingFieldCounter { ListingFieldCounter(keywords, limit: Self.limit) }
    var isOverLimit: Bool { byteCount > Self.limit.maximum }

    var duplicateCount: Int { tokens.count(where: { $0.state == .duplicate }) }
    var inNameOrSubtitleCount: Int { tokens.count(where: { $0.state == .inNameOrSubtitle }) }

    /// Bytes "Optimize" frees.
    var bytesSaved: Int { byteCount - ListingTextMeasure.utf8Bytes(in: optimized) }
    var canOptimize: Bool { bytesSaved > 0 }

    /// "Optimize · saves 27 bytes".
    var optimizeTitle: String { String(localized: "Optimize · saves \(bytesSaved) bytes") }

    /// "1 duplicate · 2 already in name or subtitle · 1 wasted space", or
    /// "No wasted bytes".
    var summary: String {
        var parts: [String] = []
        if duplicateCount > 0 {
            parts.append(String(localized: "\(duplicateCount) duplicate"))
        }
        if inNameOrSubtitleCount > 0 {
            parts.append(String(localized: "\(inNameOrSubtitleCount) already in name or subtitle"))
        }
        if wastedSpaceBytes == 1 {
            parts.append(String(localized: "1 wasted space"))
        } else if wastedSpaceBytes > 1 {
            parts.append(String(localized: "\(wastedSpaceBytes) wasted spaces"))
        }
        return parts.isEmpty ? String(localized: "No wasted bytes") : parts.joined(separator: " · ")
    }

    /// The keywords string with one token removed (its "×"), leaving the
    /// rest exactly as typed.
    func removingToken(at index: Int) -> String {
        guard partIndices.indices.contains(index) else { return keywords }
        var parts = keywords.split(separator: ",", omittingEmptySubsequences: false)
        parts.remove(at: partIndices[index])
        return parts.joined(separator: ",")
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    private static func words(in text: String) -> [String] {
        let folded = fold(text)
        var words: [String] = []
        folded.enumerateSubstrings(in: folded.startIndex..., options: .byWords) { word, _, _, _ in
            if let word { words.append(word) }
        }
        return words
    }
}
