//
//  PricingModeStoreTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("PricingModeStore")
struct PricingModeStoreTests {
    @Test func appsWithoutAChoiceUseTheDefault() {
        let store = PricingModeStore(defaults: nil, defaultMode: .showSuggestions)
        #expect(store.chosenMode(for: "1") == nil)
        #expect(store.mode(for: "1") == .showSuggestions)
        store.defaultMode = .keepPrices
        #expect(store.mode(for: "1") == .keepPrices)
    }

    @Test func choicesArePerAppAndPersist() throws {
        let suite = "PricingModeStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = PricingModeStore(defaults: defaults)
        store.setMode(.keepPrices, for: "tempo")
        store.setMode(.applyRecommended, for: "lumen")

        let reloaded = PricingModeStore(defaults: defaults)
        #expect(reloaded.chosenMode(for: "tempo") == .keepPrices)
        #expect(reloaded.mode(for: "lumen") == .applyRecommended)
        #expect(reloaded.chosenMode(for: "quiet") == nil)
    }

    @Test func onlyKeepMyPricesHidesSuggestions() {
        #expect(!PricingMode.keepPrices.showsSuggestions)
        #expect(PricingMode.showSuggestions.showsSuggestions)
        #expect(PricingMode.applyRecommended.showsSuggestions)
    }
}
