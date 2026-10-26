//
//  ListingTranslator.swift
//  AppLocalizer
//

import Foundation

/// Translates listing text from one App Store locale to another. Apple
/// Translation is the real one (`AppleListingTranslator`); tests and DEBUG
/// scenes use canned translations.
protocol ListingTranslator: Sendable {
    /// Whether this pair can be translated right now, needs a download
    /// first, or isn't supported at all.
    func availability(from source: StoreLocale, to target: StoreLocale) async -> TranslationAvailability
    /// The translation of `text`, one of `field`'s values (AI providers word
    /// keywords and What's New differently). Throws when the pair isn't ready.
    func translate(_ text: String, field: ListingField, from source: StoreLocale, to target: StoreLocale) async throws -> String
}
