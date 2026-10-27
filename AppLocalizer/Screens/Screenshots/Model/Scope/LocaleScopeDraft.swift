//
//  LocaleScopeDraft.swift
//  AppLocalizer
//

import Foundation

/// The Locale Scope sheet's edits before Save.
struct LocaleScopeDraft: Hashable, Sendable {
    var primary: String
    var localized: Set<String>

    init(scope: LocaleScope) {
        primary = scope.primary
        localized = scope.localized
    }

    func contains(_ locale: String) -> Bool {
        locale == primary || localized.contains(locale)
    }

    mutating func set(_ locale: String, included: Bool) {
        guard locale != primary else { return }
        if included { localized.insert(locale) } else { localized.remove(locale) }
    }

    /// The shortcuts above the list.
    mutating func select(_ locales: some Sequence<String>) {
        localized = Set(locales).union([primary])
    }

    var count: Int { localized.union([primary]).count }
}
