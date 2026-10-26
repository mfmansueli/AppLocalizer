//
//  GlossaryProtector.swift
//  AppLocalizer
//

import Foundation

/// Keeps glossary terms out of a translator's hands: before sending, each
/// term becomes a numbered placeholder (`⟦0⟧`); after, the placeholders
/// become the terms again, wherever the translator moved them.
///
/// Terms match case-sensitively and as whole words, longest first, so
/// "Lumen Plus" is kept as one term rather than "Lumen" plus a translated
/// "Plus".
struct GlossaryProtector: Hashable, Sendable {
    let terms: [String]

    init(terms: [String]) {
        let unique = Set(terms.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        self.terms = unique.sorted { $0.count == $1.count ? $0 < $1 : $0.count > $1.count }
    }

    /// The text to send, with every term replaced by its placeholder.
    func protect(_ text: String) -> GlossaryProtectedText {
        var protected = text
        var used: [String] = []
        for term in terms {
            let ranges = FindReplace.occurrences(of: term, in: protected, caseSensitive: true, wholeWords: true)
            guard !ranges.isEmpty else { continue }
            protected = FindReplace.replacing(ranges, in: protected, with: GlossaryProtectedText.placeholder(used.count))
            used.append(term)
        }
        return GlossaryProtectedText(original: text, text: protected, terms: used)
    }
}
