//
//  PushRecord+Title.swift
//  AppLocalizer
//

import Foundation

extension PushRecord {
    /// What a push changed, as Activity titles it: "Store Page · 24 texts in
    /// 8 locales", "Subscription Pricing · Mexico, Türkiye, India" or
    /// "Subscription Pricing · 14 territories".
    static func title(for changes: [PendingChange]) -> String {
        let sections = Array(Set(changes.map(\.section))).sorted { $0.shortcutDigit < $1.shortcutDigit }
        guard sections.count == 1, let section = sections.first else {
            let names = sections.map(\.title).formatted(.list(type: .and))
            return String(localized: "\(names) · \(changes.count) changes")
        }
        return "\(section.title) · \(detail(for: changes, in: section))"
    }

    private static func detail(for changes: [PendingChange], in section: AppWorkspaceSection) -> String {
        switch section {
        case .subscriptionPricing:
            let territories = unique(changes.map(\.title))
            if territories.count <= 3 { return territories.joined(separator: ", ") }
            return String(localized: "\(territories.count) territories")
        case .storePage:
            // Titles read "German · Subtitle"; the locale comes first.
            let locales = unique(changes.map { $0.title.components(separatedBy: " · ").first ?? $0.title })
            let texts = changes.count == 1 ? String(localized: "1 text") : String(localized: "\(changes.count) texts")
            let inLocales = locales.count == 1 ? String(localized: "1 locale") : String(localized: "\(locales.count) locales")
            return String(localized: "\(texts) in \(inLocales)")
        case .appInformation, .overview:
            return changes.count == 1 ? changes[0].title : String(localized: "\(changes.count) fields")
        }
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { seen.insert($0).inserted }
    }
}
