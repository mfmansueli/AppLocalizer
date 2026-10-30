//
//  SuggestionReviewState.swift
//  AppLocalizer
//

import Foundation

/// What the person decided about suggestions: dismissed, accepted, and who
/// suggested each accepted value. Accept All keeps a copy, so its Undo puts
/// every decision back at once.
struct SuggestionReviewState: Hashable, Codable, Sendable {
    var dismissedIDs: Set<FieldSuggestion.ID> = []
    var acceptedIDs: Set<FieldSuggestion.ID> = []
    var provenance: [SuggestionFieldKey: SuggestionProvenance] = [:]
}
