//
//  PrivacyTypeEntry.swift
//  AppLocalizer
//

import Foundation

/// One data type's row in the worksheet: the answer it shows, where that
/// answer stands, the assistant's latest suggestion (for its confidence,
/// rationale and evidence), and an assistant's different answer waiting for
/// the person to pick one.
struct PrivacyTypeEntry: Hashable, Codable, Sendable {
    var answer: PrivacyAnswer
    var status: PrivacyRowStatus
    var suggestion: PrivacySuggestion?
    /// An assistant's answer that differs from one the person gave: Keep
    /// yours, or use the assistant's.
    var conflict: PrivacySuggestion?

    /// The person's own answer.
    static func yours(_ answer: PrivacyAnswer) -> PrivacyTypeEntry {
        PrivacyTypeEntry(answer: answer, status: .yours)
    }

    /// An assistant's suggestion nobody has reviewed.
    static func suggested(_ suggestion: PrivacySuggestion) -> PrivacyTypeEntry {
        PrivacyTypeEntry(answer: suggestion.answer, status: .unreviewed, suggestion: suggestion)
    }

    /// The answer that counts, or nil while it's unreviewed.
    var countedAnswer: PrivacyAnswer? {
        status.isReviewed ? answer : nil
    }

    /// The assistant whose answer the row shows, or nil for the person's.
    var client: String? {
        status.isAssistants ? suggestion?.client : nil
    }

    /// Needs the person: unreviewed, or a conflict to settle.
    var needsReview: Bool { !status.isReviewed || conflict != nil }

    /// The person changed the answer on the page: an assistant's answer
    /// becomes "Edited by you", anything else is theirs.
    mutating func edit(_ newAnswer: PrivacyAnswer) {
        guard newAnswer != answer else { return }
        answer = newAnswer
        status = status.isAssistants ? .edited : .yours
    }
}
