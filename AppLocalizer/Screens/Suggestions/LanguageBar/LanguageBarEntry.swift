//
//  LanguageBarEntry.swift
//  AppLocalizer
//

import Foundation

/// One language in the language bar's menu.
struct LanguageBarEntry: Identifiable, Hashable, Sendable {
    let locale: StoreLocale
    /// Suggestions to review in it.
    var count: Int
    /// How many Suggest Everything still owes it.
    var comingCount = 0
    /// The app supports it and the App Store doesn't have it yet.
    var isNewPage = false

    var id: String { locale.code }

    /// "German, 5 suggestions to review, not on the App Store yet".
    var accessibilityText: String {
        var parts = [locale.name]
        switch count {
        case 0: parts.append(String(localized: "nothing to review"))
        case 1: parts.append(String(localized: "1 suggestion to review"))
        default: parts.append(String(localized: "\(count) suggestions to review"))
        }
        if comingCount > 0 { parts.append(String(localized: "\(comingCount) coming")) }
        if isNewPage { parts.append(String(localized: "not on the App Store yet")) }
        return parts.joined(separator: ", ")
    }
}
