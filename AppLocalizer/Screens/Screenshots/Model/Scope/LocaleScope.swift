//
//  LocaleScope.swift
//  AppLocalizer
//

import Foundation

/// Which locales get their own rendered set. The primary locale always
/// does; the others use its screenshots on the App Store. Leaving a locale
/// out never deletes what's live there. A restored locale is pinned: it
/// keeps its restored set and isn't re-rendered until Use Template Again.
struct LocaleScope: Codable, Hashable, Sendable {
    var primary: String
    private(set) var localized: Set<String>
    /// Restored locales and when they were restored.
    private(set) var pinned: [String: Date]

    init(primary: String, localized: Set<String> = [], pinned: [String: Date] = [:]) {
        self.primary = primary
        self.localized = localized.union([primary])
        self.pinned = pinned
    }

    func contains(_ locale: String) -> Bool {
        locale == primary || localized.contains(locale)
    }

    func isPinned(_ locale: String) -> Bool {
        pinned[locale] != nil
    }

    /// The locales rendered from the template: in scope and not pinned.
    func isRendered(_ locale: String) -> Bool {
        contains(locale) && !isPinned(locale)
    }

    mutating func set(_ locale: String, included: Bool) {
        guard locale != primary else { return }
        if included { localized.insert(locale) } else { localized.remove(locale) }
    }

    mutating func setLocalized(_ locales: some Sequence<String>) {
        localized = Set(locales).union([primary])
    }

    mutating func pin(_ locale: String, at date: Date) {
        pinned[locale] = date
    }

    /// Use Template Again.
    mutating func unpin(_ locale: String) {
        pinned[locale] = nil
    }

    /// The localized locales, primary first, then in `order`.
    func orderedLocales(in order: [String]) -> [String] {
        [primary] + order.filter { $0 != primary && localized.contains($0) }
    }

    var count: Int { localized.count }
}
