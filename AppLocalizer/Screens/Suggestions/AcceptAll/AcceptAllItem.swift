//
//  AcceptAllItem.swift
//  AppLocalizer
//

import Foundation

/// One suggestion in the Accept All sheet: which field, who suggested it and
/// why, and what it replaces.
struct AcceptAllItem: Identifiable, Hashable, Sendable {
    /// The suggestion's id.
    let id: String
    /// "Keywords", "Apple Watch · VoiceOver", "Screenshot 2 · caption".
    var title: String
    var source: SuggestionSource
    /// What the field holds now; "" reads "Empty".
    var current: String
    var suggested: String
    var reason: String
}
