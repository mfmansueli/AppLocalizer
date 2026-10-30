//
//  AppInformationSuggestionUndo.swift
//  AppLocalizer
//

import Foundation

/// What accepting a batch of App Information suggestions changed, so its
/// Undo (the toast's, or Edit → Undo) puts it back: each queued change it
/// touched as it was (nil when there was none), and the decisions about
/// suggestions before the batch.
struct AppInformationSuggestionUndo: Hashable, Sendable {
    var changes: [PendingChange.ID: PendingChange?]
    var review: SuggestionReviewState
}
