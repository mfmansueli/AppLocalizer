//
//  ListingFieldKey.swift
//  AppLocalizer
//

import Foundation

/// One cell of the listing: a field in a locale.
struct ListingFieldKey: Identifiable, Hashable, Sendable {
    let locale: StoreLocale
    let field: ListingField

    init(_ locale: StoreLocale, _ field: ListingField) {
        self.locale = locale
        self.field = field
    }

    /// Stable string form, e.g. `de-DE.subtitle`.
    var id: String { "\(locale.code).\(field.rawValue)" }

    /// The row label in review lists, e.g. "German · Subtitle".
    var title: String { "\(locale.name) · \(field.title)" }
}
