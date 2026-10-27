//
//  PricingModeStore.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Each app's pricing mode, kept in `UserDefaults`. An app without one hasn't
/// opened Pricing yet: Pricing then asks with a sheet, and everything else
/// treats it as the default from Settings.
@MainActor
@Observable
final class PricingModeStore {
    private(set) var modes: [StoreApp.ID: PricingMode]
    /// Settings → Pricing → "Pricing mode for new apps".
    var defaultMode: PricingMode

    private let defaults: UserDefaults?

    /// `defaults: nil` keeps everything in memory (tests, DEBUG scenes).
    init(defaults: UserDefaults? = .standard, defaultMode: PricingMode = .showSuggestions, modes: [StoreApp.ID: PricingMode] = [:]) {
        self.defaults = defaults
        self.defaultMode = defaultMode
        let saved = (defaults?.dictionary(forKey: Self.key) as? [String: String] ?? [:])
            .compactMapValues(PricingMode.init(rawValue:))
        self.modes = saved.merging(modes) { _, new in new }
    }

    /// The mode the person picked for this app, or nil before the first visit.
    func chosenMode(for appID: StoreApp.ID) -> PricingMode? {
        modes[appID]
    }

    /// The picked mode, or the default for apps that haven't been asked yet.
    func mode(for appID: StoreApp.ID) -> PricingMode {
        modes[appID] ?? defaultMode
    }

    func setMode(_ mode: PricingMode, for appID: StoreApp.ID) {
        modes[appID] = mode
        defaults?.set(modes.mapValues(\.rawValue), forKey: Self.key)
    }

    private static let key = "pricingModes"
}
