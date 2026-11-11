//
//  ProFeature.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer Pro adds. Free does it one at a time; Pro does it all
/// at once, plus the tools that earn the developer money and more than one
/// app. Reading, editing, pushing and anything a person already made are
/// never one of these.
enum ProFeature: String, CaseIterable, Hashable, Sendable, Identifiable {
    /// Accept All Languages, Accept All Pages, Translate All.
    case acceptAll
    /// Screenshot Autopilot: screenshots, App Preview and header artwork.
    case autopilot
    /// Recommended prices for every country.
    case recommendedPrices
    /// Retention messages and offers.
    case retention
    /// More than one app or App Store Connect account.
    case multipleApps
    /// Every screenshot template and device.
    case allTemplates

    var id: String { rawValue }

    /// The paywall's list, in this order.
    var title: String {
        switch self {
        case .acceptAll: String(localized: "Everything at once")
        case .autopilot: String(localized: "Autopilot")
        case .recommendedPrices: String(localized: "Prices for 175 countries")
        case .retention: String(localized: "Retention")
        case .multipleApps: String(localized: "Every app and team")
        case .allTemplates: String(localized: "All 14 templates, every device")
        }
    }

    var detail: String {
        switch self {
        case .acceptAll: String(localized: "Accept All Languages, Translate All and every App Information page in one step.")
        case .autopilot: String(localized: "Screenshots, App Preview and header artwork in every language, made for you.")
        case .recommendedPrices: String(localized: "Recommended prices for local purchasing power, checked country by country.")
        case .retention: String(localized: "Messages and offers when someone taps Cancel Subscription.")
        case .multipleApps: String(localized: "All your apps and App Store Connect accounts in one window.")
        case .allTemplates: String(localized: "Mac, iPad, iPhone Duo, Vision Pro and Apple Watch.")
        }
    }

    var systemImage: String {
        switch self {
        case .acceptAll: "checkmark.circle"
        case .autopilot: "wand.and.stars"
        case .recommendedPrices: "globe"
        case .retention: "arrow.uturn.backward.circle"
        case .multipleApps: "square.stack.3d.up"
        case .allTemplates: "rectangle.on.rectangle"
        }
    }
}
