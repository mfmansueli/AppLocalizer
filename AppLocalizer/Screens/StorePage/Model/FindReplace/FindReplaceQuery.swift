//
//  FindReplaceQuery.swift
//  AppLocalizer
//

import Foundation

/// "Find and replace across locales": what to look for, what to put
/// instead, and where. By default it's case-sensitive and looks in
/// Promotional Text, Description and What's New, as the sheet says.
struct FindReplaceQuery: Hashable, Sendable {
    var find: String
    var replacement: String
    var isCaseSensitive = true
    /// Only matches not touching a letter or digit on either side, so
    /// "Lumen" doesn't match inside "Lumenwelt".
    var matchesWholeWords = false
    var fields: Set<ListingField> = FindReplaceQuery.defaultFields
    /// Nil searches every locale.
    var locales: Set<StoreLocale>?

    static let defaultFields: Set<ListingField> = [.promotionalText, .description, .whatsNew]

    /// Nothing to search for yet.
    var isEmpty: Bool { find.isEmpty }
}
