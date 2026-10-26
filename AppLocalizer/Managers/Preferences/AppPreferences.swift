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

    /// General → "Confirm before pushing".
    var pushConfirmation: PushConfirmation {
        didSet { defaults.set(pushConfirmation.rawValue, forKey: Key.pushConfirmation) }
    }

    /// General → "Ask before pushing price increases".
    var confirmsPriceIncreases: Bool {
        didSet { defaults.set(confirmsPriceIncreases, forKey: Key.confirmsPriceIncreases) }
    }

    /// General → "Confirm before discarding".
    var confirmsDiscarding: Bool {
        didSet { defaults.set(confirmsDiscarding, forKey: Key.confirmsDiscarding) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaultPricingMode = defaults.string(forKey: Key.defaultPricingMode).flatMap(PricingMode.init(rawValue:)) ?? .showSuggestions
        let commission = defaults.double(forKey: Key.commissionRate)
        commissionRate = commission > 0 ? commission : 0.15
        pushConfirmation = defaults.string(forKey: Key.pushConfirmation).flatMap(PushConfirmation.init(rawValue:)) ?? .overFifty
        confirmsPriceIncreases = defaults.object(forKey: Key.confirmsPriceIncreases) as? Bool ?? true
        confirmsDiscarding = defaults.object(forKey: Key.confirmsDiscarding) as? Bool ?? true
    }

    private enum Key {
        static let defaultPricingMode = "defaultPricingMode"
        static let commissionRate = "commissionRate"
        static let pushConfirmation = "pushConfirmation"
        static let confirmsPriceIncreases = "confirmsPriceIncreases"
        static let confirmsDiscarding = "confirmsDiscarding"
    }
}
