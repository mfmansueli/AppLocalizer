//
//  LanguageBarModel.swift
//  AppLocalizer
//

import Foundation

/// What the language bar over the Store Page and Screenshots shows: the
/// language in view with its count, Accept All Languages, the arrows to the
/// languages with suggestions, and the menu of every language.
struct LanguageBarModel: Equatable, Sendable {
    var entries: [LanguageBarEntry]
    var current: StoreLocale
    /// "Don't ask again" is on: Accept All Languages accepts at once.
    var acceptsRightAway = false

    var currentEntry: LanguageBarEntry? { entries.first { $0.locale == current } }
    var hereCount: Int { currentEntry?.count ?? 0 }
    var totalCount: Int { entries.reduce(0) { $0 + $1.count } }
    var withSuggestions: [LanguageBarEntry] { entries.filter { $0.count > 0 } }
    var upToDate: [LanguageBarEntry] { entries.filter { $0.count == 0 } }
    private var others: [LanguageBarEntry] { withSuggestions.filter { $0.locale != current } }

    /// "5 suggestions here", under the language's name.
    var hereText: String {
        switch hereCount {
        case 0: String(localized: "Nothing to review here")
        case 1: String(localized: "1 suggestion here")
        default: String(localized: "\(hereCount) suggestions here")
        }
    }

    /// "27 more in 5 other languages", beside the arrows.
    var restText: String {
        if !others.isEmpty {
            let count = totalCount - hereCount
            return others.count == 1
                ? String(localized: "\(count) more in 1 other language")
                : String(localized: "\(count) more in \(others.count) other languages")
        }
        return totalCount > 0 ? String(localized: "Only this language has suggestions") : String(localized: "Every language is reviewed")
    }

    var acceptAllTitle: String {
        totalCount > 0 ? String(localized: "Accept All Languages") : String(localized: "All Languages Reviewed")
    }

    /// The menu's last row: it says when it will ask first.
    var menuAcceptAllTitle: String {
        acceptsRightAway ? String(localized: "Accept All Languages") : String(localized: "Accept All Languages…")
    }

    var acceptAllAccessibilityText: String {
        guard totalCount > 0 else { return String(localized: "Every language is reviewed") }
        let how = acceptsRightAway ? String(localized: "accepts right away") : String(localized: "shows them first")
        return String(localized: "Accept all languages: \(totalCount) suggestions in \(withSuggestions.count) languages, \(how)")
    }

    /// "Accept 5 in English".
    var acceptHereTitle: String {
        String(localized: "Accept \(hereCount) in \(Self.shortName(current))")
    }

    var pickerAccessibilityText: String {
        String(localized: "Language: \(current.name). \(hereText). Choose another language.")
    }

    /// The next language with suggestions, wrapping around.
    var next: StoreLocale? { neighbor(forward: true) }
    var previous: StoreLocale? { neighbor(forward: false) }

    private func neighbor(forward: Bool) -> StoreLocale? {
        guard let index = entries.firstIndex(where: { $0.locale == current }) else { return others.first?.locale }
        let after = entries[entries.index(after: index)...]
        let before = entries[..<index]
        let order = forward ? Array(after) + Array(before) : Array(before.reversed()) + Array(after.reversed())
        return order.first { $0.count > 0 }?.locale
    }

    /// "English" for "English (U.S.)": the button stays short.
    static func shortName(_ locale: StoreLocale) -> String {
        locale.name.components(separatedBy: " (").first ?? locale.name
    }
}
