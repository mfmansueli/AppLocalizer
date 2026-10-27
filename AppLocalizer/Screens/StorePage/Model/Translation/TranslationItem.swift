//
//  TranslationItem.swift
//  AppLocalizer
//

import Foundation

/// One missing cell to fill, with the primary locale's text as its source.
struct TranslationItem: Identifiable, Hashable, Sendable {
    let key: ListingFieldKey
    let sourceLocale: StoreLocale
    let sourceText: String
    let method: TranslationMethod
    var state: TranslationItemState = .queued

    var id: ListingFieldKey { key }

    /// The progress line's current item, e.g. "Korean · Description".
    var title: String { key.title }

    /// The translated (or copied) text, once done.
    var result: String? {
        if case let .done(text) = state { return text }
        return nil
    }
}
