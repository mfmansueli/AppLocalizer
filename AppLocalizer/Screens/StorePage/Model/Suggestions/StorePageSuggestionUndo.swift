//
//  StorePageSuggestionUndo.swift
//  AppLocalizer
//

import Foundation

/// What accepting a batch of suggestions changed, so its Undo (the toast's,
/// or Edit → Undo) puts it back: each touched field as it was, and the
/// decisions about suggestions before the batch.
struct StorePageSuggestionUndo: Hashable, Sendable {
    var drafts: [ListingFieldKey: ListingFieldDraft]
    var review: SuggestionReviewState
}
