//
//  StoreListing+Fill.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    /// "Copy from a sibling locale": fills every field the target is
    /// missing with the source's text: name, subtitle, every version text,
    /// keywords and the URLs. Text already in the target is never
    /// overwritten. Adds the target locale if it's new.
    ///
    /// Copies are your edits, not machine translation: the language is the
    /// same, so nothing was translated. Returns the fields that were filled.
    @discardableResult
    mutating func copy(from source: StoreLocale, to target: StoreLocale) -> [ListingField] {
        guard source != target else { return [] }
        addLocale(target)
        let copied = fields.filter { field in
            canEdit(field) && value(field, in: target).isEmpty && !value(field, in: source).isEmpty
        }
        for field in copied {
            edit(field, in: target, to: value(field, in: source))
        }
        return copied
    }

    /// `copy(from:to:)` for a Fill menu item.
    @discardableResult
    mutating func copy(_ pair: LocaleSiblingPair) -> [ListingField] {
        copy(from: pair.source, to: pair.target)
    }

    /// "Copy URLs from English": the privacy, support and marketing URLs
    /// the locale is missing, from the primary locale (or `source`).
    @discardableResult
    mutating func copyURLs(to target: StoreLocale, from source: StoreLocale? = nil) -> [ListingField] {
        let source = source ?? primaryLocale
        guard source != target else { return [] }
        addLocale(target)
        let copied = fields.filter { field in
            field.isURL && canEdit(field) && value(field, in: target).isEmpty && !value(field, in: source).isEmpty
        }
        for field in copied {
            edit(field, in: target, to: value(field, in: source))
        }
        return copied
    }

    /// "Send What's New to Every Locale…": a translation job for the
    /// primary locale's What's New into every other locale that has none
    /// (or every locale, with `overwriting`). Run it, then apply it with
    /// `applyTranslations(of:)`: each one is tagged machine-translated
    /// until reviewed.
    func whatsNewBroadcast(overwriting: Bool = false) -> TranslationJob {
        TranslationPlanner.plan(self, scope: .field(.whatsNew), includeFilled: overwriting)
    }
}
