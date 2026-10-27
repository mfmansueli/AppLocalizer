//
//  PriceCalculatorLimitTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Floor, ceiling, discount only, minimum proceeds, never raise and rounding.
@Suite("PriceCalculator limits")
struct PriceCalculatorLimitTests {
    private let calculator = PricingFixtures.sample.calculator

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    private func strategy(_ edit: (inout PricingStrategy) -> Void) -> PricingStrategy {
        var strategy = PricingStrategy.recommended
        strategy.customize(edit)
        return strategy
    }

    @Test func floorRoundsUpToThePointAtOrAboveIt() throws {
        let result = try calculator.calculate(PricingFixtures.annualInput("IN"), strategy: .recommended)
        #expect(result.target == money("849.75"))
        #expect(result.adjustment == .raisedToFloor)
        #expect(result.price.customerPrice == 1049)
        #expect(result.price.customerPrice >= money("1019.73"))
        #expect(result.summary == "₹3,399 equalized × 0.25 = ₹850 → raised to floor → ₹1,049")
        #expect(result.steps.suffix(2) == [
            "Below the floor (30% of base = ₹1,020) → raised to the floor",
            "Nearest price point at or above the floor → ₹1,049",
        ])
    }

    @Test(arguments: [("CH", "40"), ("NO", "439")])
    func discountOnlyCapsAtTheEqualizedPrice(example: (code: String, equalized: String)) throws {
        let result = try calculator.calculate(PricingFixtures.annualInput(example.code), strategy: .recommended)
        #expect(result.factor > 1)
        #expect(result.adjustment == .cappedAtEqualized)
        #expect(result.price.customerPrice == money(example.equalized))
        #expect(result.steps.contains("Discount only → capped at the equalized price"))
    }

    @Test func premiumsAreAllowedWithoutDiscountOnly() throws {
        let result = try calculator.calculate(PricingFixtures.annualInput("CH"), strategy: strategy { $0.discountOnly = false })
        #expect(result.adjustment == .aboveFloor)
        #expect(result.price.customerPrice == 50)
    }

    @Test func ceilingAppliesOnlyWithPremiums() throws {
        let capped = strategy {
            $0.discountOnly = false
            $0.ceiling = money("1.1")
        }
        let result = try calculator.calculate(PricingFixtures.annualInput("CH"), strategy: capped)
        #expect(result.adjustment == .loweredToCeiling)
        #expect(result.steps.contains("Above the ceiling (110% of base) → lowered to CHF 43.99"))
        #expect(result.price.customerPrice == 44)
    }

    @Test func minimumProceedsRaiseThePrice() throws {
        let minimum = strategy { $0.minimumProceeds = 12 }
        let india = try calculator.calculate(PricingFixtures.annualInput("IN"), strategy: minimum)
        #expect(india.adjustment == .minimumProceeds)
        #expect(india.price.customerPrice == 1449)
        #expect(india.steps.contains("Raised so proceeds stay at least $12.00"))
        #expect(india.steps.last == "Nearest price point at or above the minimum proceeds → ₹1,449")
        #expect(india.price.proceeds >= 12 * money("85"))
        let brazil = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: minimum)
        #expect(brazil.adjustment == .aboveFloor)
        #expect(brazil.price.customerPrice == money("109.90"))
    }

    @Test func neverRaiseKeepsTheCurrentPrice() throws {
        let input = try PricingFixtures.annualInput("MX")
        #expect(input.currentPrice == 549)
        let raising = strategy { $0.intensity = 0 }
        #expect(calculator.calculate(input, strategy: raising).price.customerPrice == 739)
        let neverRaise = strategy {
            $0.intensity = 0
            $0.neverRaise = true
        }
        let result = calculator.calculate(input, strategy: neverRaise)
        #expect(result.adjustment == .neverRaise)
        #expect(result.price.customerPrice == 549)
        #expect(result.steps.contains("Never raise → kept at the current price"))
    }

    @Test(arguments: [(PriceRounding.auto, "109.90"), (.ninetyNine, "109.99"), (.ninety, "109.90"), (.round, "110")])
    func roundingPicksTheEnding(example: (rounding: PriceRounding, price: String)) throws {
        let result = try calculator.calculate(PricingFixtures.annualInput("BR"), strategy: strategy { $0.rounding = example.rounding })
        #expect(result.price.customerPrice == money(example.price))
    }

    @Test func emptyLadderComputesTheProceedsItself() throws {
        var input = try PricingFixtures.annualInput("BR")
        input.ladder = PricingFixtures.ladder([], currency: "BRL", territoryID: "BRA")
        let result = calculator.calculate(input, strategy: .recommended)
        #expect(result.price.customerPrice == money("109.95"))
        #expect(result.price.proceeds == money("93.46"))
    }

    @Test func multiplierDefaultsToEqualizedOverBase() throws {
        let brazil = try PricingFixtures.territory("BR")
        let ladder = PricingFixtures.sample.ladder(for: brazil)
        let input = PriceCalculationInput(territory: brazil, basePrice: 40, equalizedPrice: 220, ladder: ladder)
        #expect(input.equalizationMultiplier == money("5.5"))
        let free = PriceCalculationInput(territory: brazil, basePrice: 0, equalizedPrice: 0, ladder: ladder)
        #expect(free.equalizationMultiplier == 1)
    }

    @Test func adjustmentTexts() {
        let texts: [PriceAdjustment: String] = [
            .kept: "kept", .excluded: "excluded", .aboveFloor: "above floor", .cappedAtEqualized: "capped at equalized",
            .raisedToFloor: "raised to floor", .loweredToCeiling: "lowered to ceiling", .minimumProceeds: "min. proceeds",
            .neverRaise: "never raise",
        ]
        for (adjustment, text) in texts {
            #expect(adjustment.text == text)
        }
    }
}
