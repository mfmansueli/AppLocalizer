//
//  AppWorkspaceSection.swift
//  AppLocalizer
//

import Foundation

/// The five sections of an app's workspace, picked in the toolbar (⌘1–⌘5).
enum AppWorkspaceSection: String, CaseIterable, Identifiable, Codable, Sendable {
    /// Summary cards and quick actions.
    case overview
    /// Per-territory prices for subscriptions and in-app purchases.
    case subscriptionPricing
    /// The App Store listing's text in every locale.
    case storePage
    /// The App Store preview, Autopilot, and the sets, template, captions
    /// and captures behind them.
    case screenshots
    /// Categories, age rating, App Privacy, App Review and export compliance.
    case appInformation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: String(localized: "Overview")
        // Shortened so Screenshots fits in the toolbar.
        case .subscriptionPricing: String(localized: "Pricing")
        case .storePage: String(localized: "Store Page")
        case .screenshots: String(localized: "Screenshots")
        case .appInformation: String(localized: "App Information")
        }
    }

    /// The unshortened name, for the View menu and push history:
    /// "Subscription Pricing · Mexico, Türkiye, India".
    var fullTitle: String {
        switch self {
        case .subscriptionPricing: String(localized: "Subscription Pricing")
        default: title
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .subscriptionPricing: "tag"
        case .storePage: "globe"
        case .screenshots: "photo.on.rectangle"
        case .appInformation: "info.circle"
        }
    }

    /// The digit for ⌘1–⌘5.
    var shortcutDigit: Character {
        switch self {
        case .overview: "1"
        case .subscriptionPricing: "2"
        case .storePage: "3"
        case .screenshots: "4"
        case .appInformation: "5"
        }
    }
}
