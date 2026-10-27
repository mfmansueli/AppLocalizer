//
//  ListingTranslator+Captions.swift
//  AppLocalizer
//

import Foundation

// Captions go through the Store Page's translator, not a second one. A
// caption is short marketing copy, so it's worded like promotional text.
extension ListingTranslator {
    /// The translation of one caption headline or subhead.
    func translateCaption(_ text: String, from source: StoreLocale, to target: StoreLocale) async throws -> String {
        try await translate(text, field: Self.captionField, from: source, to: target)
    }

    /// The listing field captions are translated as.
    static var captionField: ListingField { .promotionalText }
}
