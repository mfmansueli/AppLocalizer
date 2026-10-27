//
//  CaptionTranslationPlanner.swift
//  AppLocalizer
//

import Foundation

/// Which captions Translate Missing… fills: every empty caption of a
/// localized locale whose slot has a primary caption. A locale with the
/// primary's language gets a copy instead of a translation.
enum CaptionTranslationPlanner {
    static func plan(captions: CaptionBook, locales: [StoreLocale], primary: StoreLocale, slotCount: Int) -> CaptionTranslationJob {
        var items: [CaptionTranslationItem] = []
        for locale in locales where locale != primary {
            for slot in 0..<slotCount where captions.caption(locale: locale.code, slot: slot) == nil {
                guard let source = captions.caption(locale: primary.code, slot: slot) else { continue }
                let method: TranslationMethod = locale.isSameLanguage(as: primary) ? .copy : .translate
                items.append(CaptionTranslationItem(key: LocaleSlot(locale: locale.code, slot: slot), locale: locale, source: source, method: method))
            }
        }
        return CaptionTranslationJob(sourceLocale: primary, items: items)
    }
}
