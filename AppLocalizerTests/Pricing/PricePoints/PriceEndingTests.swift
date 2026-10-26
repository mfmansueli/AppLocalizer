//
//  PriceEndingTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PriceEnding and PriceRounding")
struct PriceEndingTests {
    @Test(arguments: [
        (PriceEnding.nineAfterTwoDigits, 204_480.0, 199_000.0),
        (.ninety, 109.95, 109.9),
        (.ninetyNine, 39.03, 38.99),
        (.ninetyNine, 12.4, 12.49),
        (.round, 3299.5, 3300.0),
        (.round, 945.0, 950.0),
        (.nineAfterTwoDigits, 443.4, 439.0),
        (.nineAfterThreeDigits, 1020.0, 999.0),
        (.eight, 150.0, 148.0),
        (.wholeUnits, 40.4, 40.0),
        (.ninetyEight, 20.0, 19.98),
    ])
    func gridSnapRoundsThenAppliesTheEnding(example: (ending: PriceEnding, value: Double, snapped: Double)) {
        #expect(abs(example.ending.gridSnap(example.value) - example.snapped) < 0.0001)
    }

    @Test func gridSnapOfNothingIsZero() {
        #expect(PriceEnding.ninetyNine.gridSnap(0) == 0)
        #expect(PriceEnding.ninetyNine.gridSnap(-5) == 0)
    }

    @Test(arguments: [
        (PriceEnding.ninety, "109.90", true),
        (.ninety, "107.90", false),
        (.ninety, "109.99", false),
        (.ninetyNine, "1.99", true),
        (.ninetyNine, "1.90", false),
        (.nineAfterTwoDigits, "549", true),
        (.nineAfterTwoDigits, "550", false),
        (.nineAfterTwoDigits, "990", true),
        (.nineAfterThreeDigits, "3399", true),
        (.eight, "288", true),
        (.round, "6000", true),
        (.round, "6050", false),
    ])
    func matchesPricesOnTheGrid(example: (ending: PriceEnding, price: String, matches: Bool)) {
        #expect(example.ending.matches(PricingFixtures.money(example.price)) == example.matches)
    }

    @Test(arguments: [
        ("BRL", PriceEnding.ninety),
        ("USD", .ninetyNine),
        ("EUR", .ninetyNine),
        ("GBP", .ninetyNine),
        ("JPY", .round),
        ("KRW", .round),
        ("THB", .round),
        ("MXN", .nineAfterTwoDigits),
        ("NOK", .nineAfterTwoDigits),
        ("SEK", .nineAfterTwoDigits),
        ("DKK", .nineAfterTwoDigits),
        ("CZK", .nineAfterTwoDigits),
        ("IDR", .nineAfterTwoDigits),
        ("VND", .nineAfterTwoDigits),
        ("CNY", .eight),
        ("HKD", .eight),
        ("INR", .nineAfterThreeDigits),
        ("XXX", .ninetyNine),
    ])
    func autoUsesEachCurrencysUsualEnding(example: (currency: String, ending: PriceEnding)) {
        #expect(PriceEnding.preferred(forCurrency: example.currency) == example.ending)
        #expect(PriceRounding.auto.ending(forCurrency: example.currency) == example.ending)
    }

    @Test func explicitRoundingOverridesDecimalCurrencies() {
        #expect(PriceRounding.ninetyNine.ending(forCurrency: "BRL") == .ninetyNine)
        #expect(PriceRounding.ninety.ending(forCurrency: "USD") == .ninety)
        #expect(PriceRounding.round.ending(forCurrency: "USD") == .wholeUnits)
    }

    @Test func currenciesWithoutDecimalsKeepTheirEnding() {
        #expect(PriceRounding.ninetyNine.ending(forCurrency: "JPY") == .round)
        #expect(PriceRounding.ninety.ending(forCurrency: "IDR") == .nineAfterTwoDigits)
        #expect(PriceRounding.round.ending(forCurrency: "IDR") == .round)
    }

    @Test func roundingTitles() {
        #expect(PriceRounding.allCases.map(\.title) == ["Auto", ".99", ".90", "Round"])
    }
}
