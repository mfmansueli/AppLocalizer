//
//  AppWorkspaceSection.swift
//  AppLocalizer
//

import Foundation

/// The four sections of an app's workspace, picked in the toolbar (⌘1–⌘4).
enum AppWorkspaceSection: String, CaseIterable, Identifiable, Codable, Sendable {
    /// Summary cards and quick actions.
    case overview
    /// Per-territory prices for subscriptions and in-app purchases.
    case subscriptionPricing
    /// The App Store listing's text in every locale.
    case storePage
    /// Categories, age rating, App Privacy, App Review and export compliance.
    case appInformation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: String(localized: "Overview")
        case .subscriptionPricing: String(localized: "Subscription Pricing")
        case .storePage: String(localized: "Store Page")
        case .appInformation: String(localized: "App Information")
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .subscriptionPricing: "tag"
        case .storePage: "globe"
        case .appInformation: "info.circle"
        }
    }

    /// The digit for ⌘1–⌘4.
    var shortcutDigit: Character {
        switch self {
        case .overview: "1"
        case .subscriptionPricing: "2"
        case .storePage: "3"
        case .appInformation: "4"
        }
    }
}
