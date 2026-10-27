//
//  PriceBulkEditorTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PriceBulkEditor")
struct PriceBulkEditorTests {
    private let sample = PricingFixtures.sample

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    private func row(_ code: String, proposed: Decimal? = nil) throws -> PriceBulkRow {
        let territory = try PricingFixtures.territory(code)
        let input = sample.input(for: territory, subscription: .annual)
        return PriceBulkRow(
            territory: territory,
            ladder: input.ladder,
            currentPrice: input.currentPrice ?? input.equalizedPrice,
            proposedPrice: proposed,
            equalizedPrice: input.equalizedPrice,
            equalizationMultiplier: input.equalizationMultiplier,
            feelsLikeFactor: sample.calculator.resolveFactor(for: territory, strategy: .recommended).factor
        )
    }

    @Test func multiplyStartsFromTheShownPrice() throws {
        let rows = try [row("BR"), row("MX", proposed: 439)]
        let prices = PriceBulkEditor.multiply(rows, by: money("0.9"), rounding: .auto)
        #expect(prices["BRA"]?.customerPrice == money("199.90"))
        #expect(prices["MEX"]?.customerPrice == 399)
    }

    @Test func feelLikeBaseUsesMultiplierAndFactor() throws {
        let prices = try PriceBulkEditor.feelLikeBase([row("BR"), row("JP")], basePrice: money("39.99"), rounding: .auto)
        #expect(prices["BRA"]?.customerPrice == money("109.90"))
        #expect(prices["JPN"]?.customerPrice == 3600)
    }

    @Test func resetGoesBackToEqualized() throws {
        let prices = try PriceBulkEditor.resetToEqualized([row("BR", proposed: money("109.90")), row("MX")])
        #expect(prices["BRA"]?.customerPrice == money("219.90"))
        #expect(prices["MEX"]?.customerPrice == 739)
    }

    @Test func copyFromAnotherSubscriptionSkipsMissingTerritories() throws {
        let monthly = ["BRA": money("26.90")]
        let prices = try PriceBulkEditor.copy([row("BR"), row("MX")], from: monthly, ratio: 8, rounding: .auto)
        #expect(prices.keys.sorted() == ["BRA"])
        #expect(prices["BRA"]?.customerPrice == money("214.90"))
    }

    @Test func keepingTheDurationRatio() throws {
        let monthly = ["BRA": money("26.90"), "MEX": 89]
        let prices = try PriceBulkEditor.keepingDurationRatio(
            [row("BR"), row("MX")],
            anchorPrices: monthly,
            anchorBasePrice: money("4.99"),
            basePrice: money("39.99"),
            rounding: .auto
        )
        #expect(prices["BRA"]?.customerPrice == money("214.90"))
        #expect(prices["MEX"]?.customerPrice == 709)
        #expect(PriceBulkEditor.keepingDurationRatio([], anchorPrices: monthly, anchorBasePrice: 0, basePrice: 1, rounding: .auto).isEmpty)
    }

    @Test func durationRatioText() {
        #expect(PriceBulkEditor.durationRatioText(money("39.99"), over: money("4.99")) == "8.0")
        #expect(PriceBulkEditor.durationRatioText(money("79.99"), over: money("39.99")) == "2.0")
        #expect(PriceBulkEditor.durationRatioText(1, over: 0).isEmpty)
    }
}
