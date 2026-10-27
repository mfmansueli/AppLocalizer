//
//  TranslationGlossary.swift
//  AppLocalizer
//

import Foundation

/// "Don't translate" terms (brand and product names like "Lumen Plus",
/// "Face ID") and the tone, as set in Settings → Translation and shown in
/// the Translate sheet.
struct TranslationGlossary: Hashable, Sendable, Codable {
    private(set) var terms: [String]
    var tone: TranslationTone

    init(terms: [String] = [], tone: TranslationTone = .warmAndSimple) {
        self.terms = []
        self.tone = tone
        for term in terms {
            add(term)
        }
    }

    /// Adds a trimmed term, unless it's empty or already there (ignoring case).
    mutating func add(_ term: String) {
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, !terms.contains(where: { $0.caseInsensitiveCompare(term) == .orderedSame }) else { return }
        terms.append(term)
    }

    mutating func remove(_ term: String) {
        terms.removeAll { $0 == term }
    }

    var protector: GlossaryProtector { GlossaryProtector(terms: terms) }
}
