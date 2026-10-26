//
//  GlossaryProtectedText.swift
//  AppLocalizer
//

import Foundation

/// Text ready for a translator, with glossary terms swapped for
/// placeholders, and the way back.
struct GlossaryProtectedText: Hashable, Sendable {
    let original: String
    /// What to send to the translator.
    let text: String
    /// Placeholder `n` stands for `terms[n]`.
    let terms: [String]

    static func placeholder(_ index: Int) -> String {
        "⟦\(index)⟧"
    }

    /// Puts the terms back into a translation. Placeholders may have moved
    /// or gained spaces inside the brackets (`⟦ 1 ⟧`); unknown numbers are
    /// left as they are.
    func restore(_ translated: String) -> String {
        translated.replacing(Self.pattern) { match in
            guard let index = Int(match.output.1), terms.indices.contains(index) else { return String(match.output.0) }
            return terms[index]
        }
    }

    /// Terms whose placeholder the translator dropped, to flag the
    /// suggestion for a closer look.
    func missingTerms(in translated: String) -> [String] {
        let found = Set(translated.matches(of: Self.pattern).compactMap { Int($0.output.1) })
        return terms.indices.filter { !found.contains($0) }.map { terms[$0] }
    }

    private static var pattern: Regex<(Substring, Substring)> {
        /⟦\s*(\d+)\s*⟧/
    }
}
