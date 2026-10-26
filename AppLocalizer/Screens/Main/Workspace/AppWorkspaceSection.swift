//
//  AppWorkspaceSection.swift
//  AppLocalizer
//

import Foundation

/// The two jobs AppLocalizer does for an app, picked in the workspace
/// toolbar.
enum AppWorkspaceSection: String, CaseIterable, Identifiable, Sendable {
    /// Per-territory prices for every auto-renewable subscription.
    case subscriptionPricing
    /// The App Store listing's text in every locale.
    case storePage

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .subscriptionPricing: "Subscription Pricing"
        case .storePage: "Store Page"
        }
    }

    var systemImage: String {
        switch self {
        case .subscriptionPricing: "dollarsign.arrow.circlepath"
        case .storePage: "character.book.closed"
        }
    }

    /// What the section will do — shown until it's built.
    var summary: LocalizedStringResource {
        switch self {
        case .subscriptionPricing:
            """
            Set each subscription's price in all 175 storefronts from one base price, with purchasing-power \
            adjustments and Apple's price points, then review and push the changes.
            """
        case .storePage:
            """
            Edit the name, subtitle, description, keywords, promotional text and What's New for every locale \
            side by side, translate what's missing, and push it to App Store Connect.
            """
        }
    }
}
