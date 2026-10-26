//
//  PricingMode.swift
//  AppLocalizer
//

import Foundation

/// How much AppLocalizer gets involved in an app's prices. Picked per app
/// the first time Pricing opens (default in Settings) and switchable any
/// time from the Pricing section bar.
enum PricingMode: String, CaseIterable, Identifiable, Codable, Sendable {
    /// Translation only: prices are shown read-only and never proposed.
    case keepPrices
    /// Each territory shows a suggestion next to its price; nothing is
    /// queued until "Apply".
    case showSuggestions
    /// Every proposed price is filled with the suggestion and waits in
    /// Review & Push.
    case applyRecommended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepPrices: String(localized: "Keep my prices")
        case .showSuggestions: String(localized: "Show suggestions")
        case .applyRecommended: String(localized: "Apply recommended prices")
        }
    }

    var summary: String {
        switch self {
        case .keepPrices:
            String(localized: "Only translate. Prices stay as they are and AppLocalizer never proposes a change.")
        case .showSuggestions:
            String(localized: "See a suggested price, its reason and confidence for every territory. Nothing changes until you apply it.")
        case .applyRecommended:
            String(localized: "Fill every territory with its suggested price and review the changes before anything is pushed.")
        }
    }

    var systemImage: String {
        switch self {
        case .keepPrices: "lock"
        case .showSuggestions: "lightbulb"
        case .applyRecommended: "wand.and.stars"
        }
    }

    /// Whether suggestions, the "held back" count and price indicators show.
    var showsSuggestions: Bool { self != .keepPrices }
}
