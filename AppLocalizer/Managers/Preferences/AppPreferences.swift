//
//  AppPreferences.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Settings that apply to every app, kept in `UserDefaults`: Settings →
/// Pricing and General. Per-app choices (the pricing mode) live in
/// `PricingModeStore`, translation settings in `TranslationPreferences`.
@MainActor
@Observable
final class AppPreferences {
    /// The pricing mode an app gets when Pricing first opens for it.
    var defaultPricingMode: PricingMode {
        didSet { defaults?.set(defaultPricingMode.rawValue, forKey: Key.defaultPricingMode) }
    }

    /// Pricing → "Use sales data for suggestions", when the key's role can
    /// read Sales and Trends.
    var usesSalesData: Bool {
        didSet { defaults?.set(usesSalesData, forKey: Key.usesSalesData) }
    }

    /// Pricing → the strategy a subscription starts from: base territory,
    /// rounding, index, fallback chain, intensity, limits.
    var pricingDefaults: PricingStrategy {
        didSet { defaults?.set(try? JSONEncoder().encode(pricingDefaults), forKey: Key.pricingDefaults) }
    }

    /// Apple's commission used for proceeds: 15% (Small Business Program) or 30%.
    var commissionRate: Double {
        didSet { defaults?.set(commissionRate, forKey: Key.commissionRate) }
    }

    /// General → "Confirm before pushing".
    var pushConfirmation: PushConfirmation {
        didSet { defaults?.set(pushConfirmation.rawValue, forKey: Key.pushConfirmation) }
    }

    /// General → "Ask before pushing price increases".
    var confirmsPriceIncreases: Bool {
        didSet { defaults?.set(confirmsPriceIncreases, forKey: Key.confirmsPriceIncreases) }
    }

    /// General → "Confirm before discarding".
    var confirmsDiscarding: Bool {
        didSet { defaults?.set(confirmsDiscarding, forKey: Key.confirmsDiscarding) }
    }

    /// Overview → the card introducing your own AI assistant, until its
    /// close button hides it.
    var showsAssistantIntro: Bool {
        didSet { defaults?.set(showsAssistantIntro, forKey: Key.showsAssistantIntro) }
    }

    private let defaults: UserDefaults?

    /// nil keeps everything in memory (DEBUG scenes, tests).
    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        defaultPricingMode = defaults?.string(forKey: Key.defaultPricingMode).flatMap(PricingMode.init(rawValue:)) ?? .showSuggestions
        usesSalesData = defaults?.object(forKey: Key.usesSalesData) as? Bool ?? true
        pricingDefaults = defaults?.data(forKey: Key.pricingDefaults)
            .flatMap { try? JSONDecoder().decode(PricingStrategy.self, from: $0) } ?? .recommended
        let commission = defaults?.double(forKey: Key.commissionRate) ?? 0
        commissionRate = commission > 0 ? commission : 0.15
        pushConfirmation = defaults?.string(forKey: Key.pushConfirmation).flatMap(PushConfirmation.init(rawValue:)) ?? .overFifty
        confirmsPriceIncreases = defaults?.object(forKey: Key.confirmsPriceIncreases) as? Bool ?? true
        confirmsDiscarding = defaults?.object(forKey: Key.confirmsDiscarding) as? Bool ?? true
        showsAssistantIntro = defaults?.object(forKey: Key.showsAssistantIntro) as? Bool ?? true
        // The Guided/Classic choice is gone: the guided Autopilot is the
        // only one.
        defaults?.removeObject(forKey: Key.retiredAutopilotFront)
    }

    private enum Key {
        static let defaultPricingMode = "defaultPricingMode"
        static let usesSalesData = "usesSalesData"
        static let pricingDefaults = "pricingDefaults"
        static let commissionRate = "commissionRate"
        static let pushConfirmation = "pushConfirmation"
        static let confirmsPriceIncreases = "confirmsPriceIncreases"
        static let confirmsDiscarding = "confirmsDiscarding"
        static let showsAssistantIntro = "showsAssistantIntro"
        static let retiredAutopilotFront = "autopilotFront"
    }
}
