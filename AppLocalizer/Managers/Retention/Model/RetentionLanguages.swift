//
//  RetentionLanguages.swift
//  AppLocalizer
//

import Foundation

/// The languages a retention message is written in: the app's App Store
/// languages, with the one the others are translated from first. Without
/// them, the 18 most common ones.
enum RetentionLanguages {
    /// English (U.S.) first, then the others as the design lists them.
    static let standard: [StoreLocale] = [
        .englishUS, .german, .french, .japanese, .arabic, .spanishSpain, .italian, .portugueseBrazil, .dutch, .swedish,
        .korean, .chineseSimplified, .chineseTraditional, .russian, .turkish, .polish, .hebrew, .hindi,
    ]

    /// How many the language picker shows before All languages.
    static let pickerCount = 5

    /// `codes` as locales, `source` first and the rest in the standard
    /// order, then alphabetically; the standard list when there are none.
    static func languages(codes: [String], source: StoreLocale) -> [StoreLocale] {
        let locales = Set(codes.compactMap(StoreLocaleCatalog.locale(code:)))
        guard !locales.isEmpty else { return standard }
        let order = Dictionary(uniqueKeysWithValues: standard.enumerated().map { ($1.code, $0) })
        var sorted = locales.subtracting([source]).sorted { lhs, rhs in
            switch (order[lhs.code], order[rhs.code]) {
            case let (left?, right?): left < right
            case (.some, nil): true
            case (nil, .some): false
            case (nil, nil): lhs.name < rhs.name
            }
        }
        sorted.insert(source, at: 0)
        return sorted
    }

    /// The editor's short name: "English" for English (U.S.) when it's the
    /// only English, else the catalog's.
    static func shortName(of locale: StoreLocale, among locales: [StoreLocale]) -> String {
        let english = locales.filter { $0.languageCode == "en" }
        if locale.languageCode == "en", english.count == 1 { return String(localized: "English") }
        return locale.name
    }
}
