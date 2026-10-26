//
//  AppPreferences.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Settings that apply to every app, kept in `UserDefaults`. Per-app choices
/// (the pricing mode) live in `PricingModeStore`.
@MainActor
@Observable
final class AppPreferences {
    /// The pricing mode an app gets when Pricing first opens for it.
    var defaultPricingMode: PricingMode {
        didSet { defaults.set(defaultPricingMode.rawValue, forKey: Key.defaultPricingMode) }
    }

    /// Apple's commission used for proceeds: 15% (Small Business Program) or 30%.
    var commissionRate: Double {
        didSet { defaults.set(commissionRate, forKey: Key.commissionRate) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaultPricingMode = defaults.string(forKey: Key.defaultPricingMode).flatMap(PricingMode.init(rawValue:)) ?? .showSuggestions
        let commission = defaults.double(forKey: Key.commissionRate)
        commissionRate = commission > 0 ? commission : 0.15
    }

    private enum Key {
        static let defaultPricingMode = "defaultPricingMode"
        static let commissionRate = "commissionRate"
    }
}
