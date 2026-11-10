//
//  FieldSuggestionArchive.swift
//  AppLocalizer
//

import Foundation

/// Everything `FieldSuggestionStore` keeps between launches.
struct FieldSuggestionArchive: Hashable, Codable, Sendable {
    var suggestions: [FieldSuggestion] = []
    var review = SuggestionReviewState()
    /// The number the next `sg_<n>` id takes.
    var nextNumber = 1
    /// Optional because files saved before it existed don't have the key,
    /// and a required key would make the whole archive unreadable.
    var hiddenIDs: Set<FieldSuggestion.ID>?
}
