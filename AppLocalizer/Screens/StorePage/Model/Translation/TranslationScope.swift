//
//  TranslationScope.swift
//  AppLocalizer
//

import Foundation

/// Which cells "Translate Missing" covers: one field, some locales (the
/// sheet's checkboxes), or everything. Nil means no restriction.
struct TranslationScope: Hashable, Sendable {
    var fields: Set<ListingField>?
    var locales: Set<StoreLocale>?

    static let everything = TranslationScope()

    static func field(_ field: ListingField) -> TranslationScope {
        TranslationScope(fields: [field])
    }

    static func locale(_ locale: StoreLocale) -> TranslationScope {
        TranslationScope(locales: [locale])
    }

    func includes(_ field: ListingField) -> Bool {
        fields?.contains(field) ?? true
    }

    func includes(_ locale: StoreLocale) -> Bool {
        locales?.contains(locale) ?? true
    }
}
