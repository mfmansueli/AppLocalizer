//
//  AutopilotAppProfile.swift
//  AppLocalizer
//

import Foundation

/// What the app is, in its own words: its store page (name, subtitle,
/// promotional text, the description's opening and, per language, the
/// words people search for), its categories and its icon's colors. The
/// design brief carries it so the header, the search image and the set's
/// look are about what this app does, not any app in its category.
struct AutopilotAppProfile: Hashable, Sendable {
    /// One language's name, subtitle and keywords.
    struct Language: Hashable, Sendable {
        var locale: String
        var name: String
        var subtitle: String
        var keywords: [String]
    }

    var name: String
    var subtitle: String
    /// "Lifestyle", "Health & Fitness".
    var categories: [String]
    var promotionalText: String
    /// The description's opening, cut at a sentence (`opening(of:)`).
    var description: String
    /// The plan's languages, primary first, with what their page has.
    var languages: [Language]
    /// The icon's light and dark ends, "#7C86FF".
    var iconColors: [String]

    /// Each language's name (locale → name), for what the artwork writes
    /// as the app's name there.
    var names: [String: String] {
        Dictionary(languages.map { ($0.locale, $0.name) }) { first, _ in first }
    }

    /// How much of the description the brief carries.
    static let descriptionLimit = 700

    /// The description's first paragraphs up to `limit` characters, cut
    /// after the last whole sentence (or word) that fits.
    static func opening(of description: String, limit: Int = descriptionLimit) -> String {
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count > limit else { return text }
        let head = String(text.prefix(limit))
        let enders: [Character] = [".", "!", "?", "。", "！", "？"]
        if let end = head.lastIndex(where: { enders.contains($0) }), head.distance(from: head.startIndex, to: end) >= limit / 3 {
            return String(head[...end])
        }
        let words = head.split(separator: " ", omittingEmptySubsequences: false).dropLast().joined(separator: " ")
        return (words.isEmpty ? head : words) + "…"
    }

    /// The keywords field split into its terms, in order, each once.
    static func keywords(_ field: String) -> [String] {
        var seen: Set<String> = []
        return field.split(whereSeparator: { [",", "，", "、", ";"].contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }
}
