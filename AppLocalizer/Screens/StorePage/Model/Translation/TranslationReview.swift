//
//  TranslationReview.swift
//  AppLocalizer
//

import Foundation

/// "38 suggestions from Apple Translation": accept or reject each, then
/// Done applies the accepted ones with `StoreListing.apply(_:)`.
struct TranslationReview: Hashable, Sendable {
    private(set) var suggestions: [TranslationSuggestion]

    var acceptedCount: Int { suggestions.count(where: { $0.decision == .accepted }) }
    var pendingCount: Int { suggestions.count(where: { $0.decision == .pending }) }
    var rejectedCount: Int { suggestions.count(where: { $0.decision == .rejected }) }
    var accepted: [TranslationSuggestion] { suggestions.filter { $0.decision == .accepted } }

    /// "3 accepted · 35 to decide".
    var statusLine: String {
        String(localized: "\(acceptedCount) accepted · \(pendingCount) to decide")
    }

    mutating func accept(_ id: ListingFieldKey) {
        decide(id, .accepted)
    }

    mutating func reject(_ id: ListingFieldKey) {
        decide(id, .rejected)
    }

    /// "Undo" on an accepted or rejected row.
    mutating func undo(_ id: ListingFieldKey) {
        decide(id, .pending)
    }

    /// "Accept All" keeps the rejections.
    mutating func acceptAll() {
        for index in suggestions.indices where suggestions[index].decision == .pending {
            suggestions[index].decision = .accepted
        }
    }

    mutating func rejectAll() {
        for index in suggestions.indices {
            suggestions[index].decision = .rejected
        }
    }

    private mutating func decide(_ id: ListingFieldKey, _ decision: TranslationSuggestionDecision) {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { return }
        suggestions[index].decision = decision
    }
}
