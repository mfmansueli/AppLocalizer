//
//  SourceComparisonTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Territory tab's source comparison bars.
@Suite("PriceCalculator source comparison")
struct SourceComparisonTests {
    private let calculator = PricingFixtures.sample.calculator

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    @Test func brazilComparesEverySource() throws {
        let bars = try calculator.compareSources(PricingFixtures.annualInput("BR"), strategy: .recommended)
        #expect(bars.map(\.title) == ["Current", "Equalized", "Big Mac Index", "World Bank PPP price level", "IMF implied PPP rate", "Custom index"])
        #expect(bars.map(\.price) == [money("219.90"), money("219.90"), money("164.90"), money("109.90"), money("114.90"), money("119.90")])
        #expect(bars.map(\.canUse) == [false, true, true, true, true, true])
    }

    @Test func eachIndexIsTriedAloneEvenWhenExcluded() throws {
        var strategy = PricingStrategy.recommended
        strategy.customize {
            $0.indexSource = .bigMac
            $0.excludedTerritoryIDs = ["JPN"]
        }
        let bars = try calculator.compareSources(PricingFixtures.annualInput("JP"), strategy: strategy)
        #expect(bars.map(\.price) == [6000, 6000, 3300, 3600, 3500, nil])
        #expect(bars.last?.canUse == false)
    }

    @Test func territoriesWithoutDataShowNoData() throws {
        let bars = try calculator.compareSources(PricingFixtures.annualInput("AI"), strategy: .recommended)
        #expect(bars.dropFirst(2).allSatisfy { $0.price == nil })
    }
}
