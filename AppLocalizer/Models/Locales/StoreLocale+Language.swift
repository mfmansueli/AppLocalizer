//
//  StoreLocale+Language.swift
//  AppLocalizer
//

import Foundation

extension StoreLocale {
    /// Same language and script, so text can be copied without translating:
    /// en-US → en-GB, pt-BR → pt-PT, fr-FR → fr-CA. Simplified and
    /// Traditional Chinese differ in script.
    func isSameLanguage(as other: StoreLocale) -> Bool {
        language.languageCode == other.language.languageCode && language.script == other.language.script
    }
}
