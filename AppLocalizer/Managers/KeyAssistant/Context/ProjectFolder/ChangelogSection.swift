//
//  ChangelogSection.swift
//  AppLocalizer
//

import Foundation

/// One version's part of a CHANGELOG.md: the heading that names it ("## 1.4",
/// "## [1.4] - 2026-10-01", "## v1.4") and what's under it, up to the next
/// heading of the same level. Without that version, the first section.
struct ChangelogSection: Hashable, Sendable {
    /// "1.4" or "Unreleased", from the heading.
    var title: String
    var text: String

    init?(markdown: String, version: String?) {
        let lines = markdown.components(separatedBy: .newlines)
        let headings = lines.indices.compactMap { index -> (index: Int, level: Int, title: String)? in
            let line = lines[index]
            let level = line.prefix { $0 == "#" }.count
            guard (1...3).contains(level), line.dropFirst(level).first == " " else { return nil }
            return (index, level, line.dropFirst(level).trimmingCharacters(in: .whitespaces))
        }
        // A level-1 title ("# Changelog") usually sits above the versions.
        let level = headings.dropFirst().map(\.level).min() ?? headings.first?.level
        let sections = headings.filter { $0.level == level }
        guard !sections.isEmpty else { return nil }
        let chosen = version.flatMap { version in sections.first { Self.names(version, $0.title) } } ?? sections[0]
        let end = headings.first { $0.index > chosen.index && $0.level <= chosen.level }?.index ?? lines.count
        let body = lines[(chosen.index + 1)..<end].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return nil }
        title = Self.version(in: chosen.title) ?? chosen.title
        text = body
    }

    /// Whether a heading such as "[1.4] - 2026-10-01" or "1.4.0" is for
    /// `version`.
    private static func names(_ version: String, _ heading: String) -> Bool {
        guard let found = Self.version(in: heading) else { return false }
        return found == version || found == version + ".0"
    }

    /// "1.4" in "[v1.4] - 2026-10-01"; nil for "Unreleased".
    private static func version(in heading: String) -> String? {
        let word = heading.split { " []()-".contains($0) }.first.map(String.init) ?? ""
        let trimmed = word.hasPrefix("v") || word.hasPrefix("V") ? String(word.dropFirst()) : word
        return trimmed.first?.isNumber == true ? trimmed : nil
    }
}
