//
//  StorePageViewModel+Editing.swift
//  AppLocalizer
//

import Foundation

// Editing fields, keywords, machine-translation tags and Fill. Every
// change goes through `StoreListing`, so its rules apply, then `commit(_:)`.
extension StorePageViewModel {
    /// You typed in a field. Ignored when the field is read-only.
    func edit(_ field: ListingField, in locale: StoreLocale, to value: String) {
        guard var listing, listing.canEdit(field), listing.value(field, in: locale) != value else { return }
        listing.edit(field, in: locale, to: value)
        commit(listing)
    }

    /// "Mark Reviewed" on one field: the text stays, the tag goes.
    func markReviewed(_ field: ListingField, in locale: StoreLocale) {
        guard var listing else { return }
        listing.markReviewed(field, in: locale)
        commit(listing)
    }

    /// "Mark All Reviewed" for the editor's locale.
    func markAllReviewed(in locale: StoreLocale) {
        guard var listing else { return }
        listing.markReviewed(locale)
        commit(listing)
    }

    func machineTranslatedFields(in locale: StoreLocale) -> [ListingField] {
        listing?.machineTranslatedFields(in: locale) ?? []
    }

    // MARK: - Keywords

    /// Tokens, bytes and waste for a locale's keywords, against its own
    /// name and subtitle.
    func keywordAnalysis(in locale: StoreLocale) -> KeywordAnalysis {
        KeywordAnalysis(keywords: value(.keywords, in: locale), name: value(.name, in: locale), subtitle: value(.subtitle, in: locale))
    }

    /// A token's "×".
    func removeKeyword(at index: Int, in locale: StoreLocale) {
        edit(.keywords, in: locale, to: keywordAnalysis(in: locale).removingToken(at: index))
    }

    /// "Optimize · saves n bytes": drops duplicates, words already in the
    /// name or subtitle, and spaces after commas.
    func optimizeKeywords(in locale: StoreLocale) {
        edit(.keywords, in: locale, to: keywordAnalysis(in: locale).optimized)
    }

    // MARK: - Fill

    /// "Copy from a sibling locale" items that have something to copy.
    var siblingPairs: [LocaleSiblingPair] {
        guard let listing else { return [] }
        return StoreLocaleCatalog.siblingPairs.filter { pair in
            listing.contains(pair.source) && listing.fields.contains { field in
                listing.canEdit(field) && !listing.value(field, in: pair.source).isEmpty && listing.value(field, in: pair.target).isEmpty
            }
        }
    }

    /// Copies what the target is missing from its sibling, as your edits.
    func copy(_ pair: LocaleSiblingPair) {
        guard var listing else { return }
        let copied = listing.copy(pair)
        commit(listing)
        notice = copied.count == 1
            ? String(localized: "Copied 1 field from \(pair.source.name) to \(pair.target.name).")
            : String(localized: "Copied \(copied.count) fields from \(pair.source.name) to \(pair.target.name).")
    }

    /// "Copy URLs from English": the URLs `locale` is missing, from the
    /// primary locale.
    func copyURLs(to locale: StoreLocale) {
        guard var listing else { return }
        listing.copyURLs(to: locale)
        commit(listing)
    }

    /// Copies the primary locale's URLs into every locale missing them.
    func copyURLsToEveryLocale() {
        guard var listing else { return }
        var count = 0
        for locale in listing.locales where locale != listing.primaryLocale {
            count += listing.copyURLs(to: locale).count
        }
        commit(listing)
        notice = count == 1 ? String(localized: "Copied 1 URL.") : String(localized: "Copied \(count) URLs.")
    }

    /// Locales missing a URL the primary locale has.
    var hasURLsToCopy: Bool {
        guard let listing else { return false }
        return listing.locales.contains { locale in
            locale != listing.primaryLocale && listing.fields.contains { field in
                field.isURL && listing.canEdit(field) && listing.value(field, in: locale).isEmpty
                    && !listing.value(field, in: listing.primaryLocale).isEmpty
            }
        }
    }

    /// App Store locales "Add Locale" offers, by name.
    var addableLocales: [StoreLocale] {
        (listing?.addableLocales ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    // MARK: - Editor navigation

    /// The editor's locale picker: the App Store page's locales, primary
    /// first, then the new ones (`newEditorLocales`).
    var editorLocales: [StoreLocale] { appStoreEditorLocales + newEditorLocales }

    /// The picker's first part: the locales the App Store page has.
    var appStoreEditorLocales: [StoreLocale] {
        (listing?.displayLocales ?? []).filter { !isNewLanguage($0) }
    }

    /// The previous or next locale in the picker (‹ ›).
    func stepEditorLocale(by offset: Int) {
        let locales = editorLocales
        guard let current = editorLocale, let index = locales.firstIndex(of: current), !locales.isEmpty else { return }
        editorLocale = locales[(index + offset + locales.count) % locales.count]
        editorFocus = nil
    }

    /// The editor's locale has no text at all: "Korean has no text yet".
    func isEmptyLocale(_ locale: StoreLocale) -> Bool {
        listing?.localeListing(locale)?.isEmpty ?? true
    }
}
