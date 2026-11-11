//
//  PaywallContext.swift
//  AppLocalizer
//

import Foundation

/// Why the paywall opened: the action that needed Pro, in the person's own
/// numbers, or the toolbar's Pro button (`menu`, no card). The card says
/// what was blocked and that the one-at-a-time way stays free.
enum PaywallContext: Hashable, Sendable {
    case acceptAllLanguages(suggestions: Int, languages: Int)
    case acceptAllPages(suggestions: Int, pages: Int)
    case translateAll(languages: Int)
    case autopilot
    case recommendedPrices(countries: Int)
    case retention
    case secondApp
    case template
    case menu

    /// The feature highlighted in the paywall's list.
    var feature: ProFeature? {
        switch self {
        case .acceptAllLanguages, .acceptAllPages, .translateAll: .acceptAll
        case .autopilot: .autopilot
        case .recommendedPrices: .recommendedPrices
        case .retention: .retention
        case .secondApp: .multipleApps
        case .template: .allTemplates
        case .menu: nil
        }
    }

    /// "Accept All Languages is part of Pro".
    var title: String? {
        switch self {
        case .acceptAllLanguages: String(localized: "Accept All Languages is part of Pro")
        case .acceptAllPages: String(localized: "Accept All Pages is part of Pro")
        case .translateAll: String(localized: "Translate All is part of Pro")
        case .autopilot: String(localized: "Autopilot is part of Pro")
        case .recommendedPrices: String(localized: "Recommended prices are part of Pro")
        case .retention: String(localized: "Retention is part of Pro")
        case .secondApp: String(localized: "More than one app is part of Pro")
        case .template: String(localized: "This template is part of Pro")
        case .menu: nil
        }
    }

    var detail: String? {
        switch self {
        case let .acceptAllLanguages(suggestions, languages):
            String(localized: """
            Accept \(suggestions) suggestions in \(languages) languages in one step. Accepting one suggestion, or one language, \
            at a time stays free.
            """)
        case let .acceptAllPages(suggestions, pages):
            String(localized: "Accept \(suggestions) suggestions on \(pages) pages in one step. Accepting them one at a time stays free.")
        case let .translateAll(languages):
            String(localized: "Translate what’s missing in \(languages) languages in one step. Writing or translating one language at a time stays free.")
        case .autopilot:
            String(localized: """
            Screenshots, the App Preview and header artwork in every language, made while you do something else. Editing \
            screenshots yourself stays free.
            """)
        case let .recommendedPrices(countries):
            String(localized: "Set \(countries) prices for local purchasing power in one step, previewed country by country. Setting any price yourself stays free.")
        case .retention:
            String(localized: "Messages and offers for people who are about to cancel, in every language.")
        case .secondApp:
            String(localized: "Work on all your apps and App Store Connect accounts in one window. Your first app stays free, with everything you made in it.")
        case .template:
            String(localized: """
            All 14 templates on every device: Mac, iPad, iPhone Duo, Vision Pro and Apple Watch. Three templates on \
            iPhone and iPad stay free.
            """)
        case .menu: nil
        }
    }

    /// After buying, the button that finishes what they started: "Accept
    /// 32 Suggestions…".
    var continueTitle: String? {
        switch self {
        case let .acceptAllLanguages(suggestions, _), let .acceptAllPages(suggestions, _):
            String(localized: "Accept \(suggestions) Suggestions…")
        case .translateAll: String(localized: "Translate All…")
        case .autopilot: String(localized: "Start Autopilot…")
        case .recommendedPrices: String(localized: "Accept Recommended Prices")
        case .retention: String(localized: "Open Retention")
        case .secondApp: String(localized: "Open the App")
        case .template: String(localized: "Use the Template")
        case .menu: nil
        }
    }
}
