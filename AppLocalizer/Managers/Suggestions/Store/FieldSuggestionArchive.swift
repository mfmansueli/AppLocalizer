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
}
