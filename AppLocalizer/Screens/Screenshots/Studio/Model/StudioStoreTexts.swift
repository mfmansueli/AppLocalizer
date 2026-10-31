//
//  StudioStoreTexts.swift
//  AppLocalizer
//

import Foundation

/// The version's languages and each one's name and subtitle, for the App
/// Store preview's header.
struct StudioStoreTexts: Hashable, Sendable {
    /// Primary first, then App Store Connect's order.
    var locales: [StoreLocale] = []
    var names: [String: String] = [:]
    var subtitles: [String: String] = [:]

    init() {}

    init(content: StorePageContent) {
        let primary = content.primaryLocale
        locales = [primary] + content.locales.filter { $0 != primary }
        for (locale, texts) in content.texts {
            names[locale.code] = texts[.name]
            subtitles[locale.code] = texts[.subtitle]
        }
        if names[primary.code] == nil { names[primary.code] = content.appName }
    }

    /// The name in `locale`, else the primary language's.
    func name(for locale: String, primary: String) -> String? {
        names[locale] ?? names[primary]
    }

    func subtitle(for locale: String, primary: String) -> String? {
        subtitles[locale] ?? subtitles[primary]
    }
}
