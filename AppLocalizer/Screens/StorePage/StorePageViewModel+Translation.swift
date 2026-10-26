//
//  StorePageViewModel+Translation.swift
//  AppLocalizer
//

import Foundation

// Translate Missing, Send What's New to Every Locale, and the suggestions.
extension StorePageViewModel {
    /// Opens "Translate missing fields" for a scope (everything by default).
    func presentTranslate(scope: TranslationScope = .everything, includeFilled: Bool = false) {
        guard listing != nil else { return }
        translation.prepare(scope: scope, includeFilled: includeFilled)
        sheet = .translate
    }

    /// "Translate from English (U.S.)…" on an empty locale.
    func presentTranslate(locale: StoreLocale) {
        presentTranslate(scope: .locale(locale))
    }

    /// "Send What's New to Every Locale…": the primary locale's What's New
    /// translated into every other locale, replacing what's there.
    func presentWhatsNewBroadcast() {
        presentTranslate(scope: .field(.whatsNew), includeFilled: true)
    }

    /// The sheet's Translate button: closes it and starts the batch.
    func startTranslation() {
        sheet = nil
        translation.start()
    }

    /// The suggestions' Done: accepted ones become pending changes tagged
    /// machine-translated.
    func finishSuggestions() {
        guard var listing, let review = translation.finish() else { return }
        let count = listing.apply(review)
        commit(listing)
        if count > 0 {
            notice = count == 1 ? String(localized: "Added 1 translation to Review & Push.") : String(localized: "Added \(count) translations to Review & Push.")
        }
    }
}
