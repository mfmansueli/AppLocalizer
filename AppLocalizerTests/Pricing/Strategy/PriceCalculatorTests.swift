//
//  PriceCalculatorTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The design README's worked examples (section 10), step by step.
@Suite("PriceCalculator worked examples")
struct PriceCalculatorTests {
    private let calculator = PricingFixtures.sample.calculator

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    /// Big Mac Index, World Bank fallback, intensity 80%, floor 35%.
    private var bigMacStrategy: PricingStrategy {
        var strategy = PricingStrategy.recommended
        strategy.customize {
            $0.indexSource = .bigMac
            $0.fallback = [.index(.worldBank), .regionMedian, .equalized]
            $0.intensity = money("0.8")
            $0.floor = money("0.35")
        }
        return strategy
    }

    @Test func brazilRecommended() throws {
        let input = try PricingFixtures.annualInput("BR")
        #expect(input.equalizedPrice == money("219.90"))
        #expect(input.equalizationMultiplier == money("5.5"))
        let result = calculator.calculate(input, strategy: .recommended)
        #expect(result.factor == money("0.5"))
        #expect(result.target == money("109.95"))
        #expect(result.price.customerPrice == money("109.90"))
        #expect(result.adjustment == .aboveFloor)
        #expect(result.provenance.kind == .index(.worldBank))
        #expect(!result.provenance.isFallback)
        #expect(result.provenance.badge == "WB 2024")
        #expect(result.summary == "R$ 219,90 equalized × 0.5 = R$ 109,95 → above floor → R$ 109,90")
        #expect(result.steps == [
            "R$ 219,90 — Apple’s equalized price for $39.99",
            "× 0.50 (World Bank 2024) = R$ 109,95",
            "Above the floor (30% of base = R$ 65,98)",
            "Nearest price point → R$ 109,90",
        ])
        #expect(PriceChange(old: input.equalizedPrice, new: result.price.customerPrice).percentText == "−50%")
    }

    @Test func brazilBigMacAt80Percent() throws {
        let strategy = bigMacStrategy
        #expect(strategy.method == .priceIndex)
        let result = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: strategy)
        #expect(result.factor == money("0.75"))
        #expect(result.multiplier == money("0.8"))
        #expect(result.target == money("175.92"))
        #expect(result.price.customerPrice == money("174.90"))
        #expect(result.provenance.badge == "Big Mac Jan 26")
        #expect(result.steps == [
            "R$ 219,90 — Apple’s equalized price for $39.99",
            "× (1 − 0.80 + 0.80 × 0.75) = × 0.800 (Big Mac, Jan 2026) = R$ 175,92",
            "Above the floor (35% of base = R$ 76,98)",
            "Nearest price point → R$ 174,90",
        ])
    }

    @Test func brazilBigMacAtFullIntensity() throws {
        var strategy = bigMacStrategy
        strategy.customize { $0.intensity = 1 }
        let result = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: strategy)
        #expect(result.summary == "R$ 219,90 equalized × 0.75 = R$ 164,93 → above floor → R$ 164,90")
        #expect(result.price.customerPrice == money("164.90"))
    }

    @Test func japanExcludedStaysEqualized() throws {
        var strategy = bigMacStrategy
        strategy.customize { $0.intensity = 1 }
        let input = try PricingFixtures.annualInput("JP")
        #expect(calculator.calculate(input, strategy: strategy).price.customerPrice == 3300)
        strategy.customize { $0.excludedTerritoryIDs = ["JPN"] }
        let result = calculator.calculate(input, strategy: strategy)
        #expect(result.price.customerPrice == 6000)
        #expect(result.isExcluded)
        #expect(result.adjustment == .excluded)
        #expect(result.provenance.badge == "Excluded")
        #expect(result.summary == "¥6,000 equalized → excluded → ¥6,000")
        #expect(result.steps == ["¥6,000 — Apple’s equalized price for $39.99", "Excluded from the index, so it stays equalized"])
    }

    @Test func appleEqualizationKeepsEveryPrice() throws {
        var strategy = PricingStrategy.recommended
        strategy.customize { $0.method = .equalized }
        let result = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: strategy)
        #expect(result.price.customerPrice == money("219.90"))
        #expect(result.adjustment == .kept)
        #expect(result.provenance.badge == "Equalized")
        #expect(result.summary == "R$ 219,90 equalized → kept")
        #expect(result.steps.last == "Apple equalization: no index applied")
    }

    @Test func partialIntensityBlendsTowardEqualized() throws {
        var strategy = PricingStrategy.recommended
        strategy.customize { $0.intensity = money("0.5") }
        let result = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: strategy)
        #expect(result.multiplier == money("0.75"))
        #expect(result.price.customerPrice == money("164.90"))
        #expect(result.steps[1] == "× (1 − 0.50 + 0.50 × 0.50) = × 0.750 (World Bank 2024) = R$ 164,93")
    }

    @Test func tiersReplaceTheFactorWithTheTierShare() throws {
        var strategy = PricingStrategy.recommended
        strategy.customize { $0.tiersEnabled = true }
        let brazil = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: strategy)
        #expect(brazil.tier == 3)
        #expect(brazil.tierLabel == "T3")
        #expect(brazil.factor == money("0.6"))
        #expect(brazil.price.customerPrice == money("129.90"))
        #expect(brazil.steps[1] == "× 0.60 (World Bank 2024, tier 3) = R$ 131,94")
        let germany = try calculator.calculate(PricingFixtures.annualInput("DE"), strategy: strategy)
        #expect(germany.tierLabel == "T1")
        #expect(germany.price.customerPrice == money("39.99"))
    }

    @Test func regionalTiersUseTheRegionMultiplier() throws {
        var strategy = PricingStrategy.recommended
        strategy.customize { $0.method = .regionalTiers }
        let brazil = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: strategy)
        #expect(brazil.provenance.kind == .regionalTier(.americas))
        #expect(brazil.provenance.badge == "Region tier")
        #expect(brazil.steps[1] == "× 0.70 (Americas tier) = R$ 153,93")
        #expect(brazil.price.customerPrice == money("154.90"))
        let germany = try calculator.calculate(PricingFixtures.annualInput("DE"), strategy: strategy)
        #expect(germany.price.customerPrice == money("35.99"))
    }

    @Test func baseTerritoryStaysAtTheBasePrice() throws {
        let result = try calculator.calculate(PricingFixtures.annualInput("US"), strategy: .recommended)
        #expect(result.factor == 1)
        #expect(result.price.customerPrice == money("39.99"))
    }

    @Test func monthlyUsesItsOwnBasePrice() throws {
        let brazil = try PricingFixtures.territory("BR")
        let input = PricingFixtures.sample.input(for: brazil, subscription: .monthly)
        let result = calculator.calculate(input, strategy: .recommended)
        #expect(result.steps[0] == "R$ 26,90 — Apple’s equalized price for $4.99")
        #expect(result.price.customerPrice == money("12.90"))
    }
}
