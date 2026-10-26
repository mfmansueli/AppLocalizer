//
//  TranslationPlanner.swift
//  AppLocalizer
//

import Foundation

/// Plans "Translate Missing": which cells to fill, from which text.
enum TranslationPlanner {
    /// Every missing (empty) cell in scope that the source locale has text
    /// for, locales in the order they were added, fields in column order.
    /// Read-only fields are skipped. `includeFilled` also re-translates
    /// cells that have text (What's New sent to every locale).
    static func plan(
        _ listing: StoreListing,
        scope: TranslationScope = .everything,
        from source: StoreLocale? = nil,
        includeFilled: Bool = false
    ) -> TranslationJob {
        let source = source ?? listing.primaryLocale
        let fields = listing.fields.filter { scope.includes($0) && listing.canEdit($0) }
        let items = listing.locales.filter { $0 != source && scope.includes($0) }.flatMap { locale in
            fields.compactMap { field -> TranslationItem? in
                let sourceText = listing.value(field, in: source)
                let current = listing.value(field, in: locale)
                guard !sourceText.isEmpty, current.isEmpty || (includeFilled && current != sourceText) else { return nil }
                let isCopy = field.isURL || locale.isSameLanguage(as: source)
                return TranslationItem(
                    key: ListingFieldKey(locale, field),
                    sourceLocale: source,
                    sourceText: sourceText,
                    method: isCopy ? .copy : .translate
                )
            }
        }
        return TranslationJob(sourceLocale: source, items: items)
    }
}
