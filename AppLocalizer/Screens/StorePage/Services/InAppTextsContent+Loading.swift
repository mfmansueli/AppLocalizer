//
//  InAppTextsContent+Loading.swift
//  AppLocalizer
//

import Foundation

extension InAppTextsContent {
    /// One localization as the loader reads it.
    struct LoadedLocalization: Sendable {
        /// The localization resource ID.
        var id: String
        /// App Store Connect's locale code.
        var locale: String
        var name: String?
        var description: String?
    }

    /// Adds a product and its localizations.
    mutating func add(_ product: InAppTextProduct, resourceID: String, localizations: [LoadedLocalization]) {
        products.append(product)
        productResourceIDs[product.id] = resourceID
        for localization in localizations {
            guard let locale = StoreLocaleCatalog.locale(code: localization.locale) else { continue }
            productLocalizations[product.id, default: [:]][locale] = localization.id
            set(localization.name, column: "\(product.id).name", in: locale)
            set(localization.description, column: "\(product.id).description", in: locale)
        }
    }

    /// Records a text; empty ones are left out, so they read as missing.
    mutating func set(_ text: String?, column: String, in locale: StoreLocale) {
        guard let text, !text.isEmpty else { return }
        texts[locale, default: [:]][column] = text
    }
}
