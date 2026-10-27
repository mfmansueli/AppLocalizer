//
//  CurrencyFormatTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("CurrencyFormat")
struct CurrencyFormatTests {
    /// The design's own examples, one per currency style.
    @Test(arguments: [
        ("USD", "39.99", "$39.99"),
        ("BRL", "219.9", "R$ 219,90"),
        ("EUR", "39.99", "39,99 €"),
        ("GBP", "35.99", "£35.99"),
        ("CAD", "55.99", "CA$ 55.99"),
        ("KRW", "56000", "₩56,000"),
        ("JPY", "6000", "¥6,000"),
        ("IDR", "639000", "Rp 639.000"),
        ("VND", "249000", "₫ 249.000"),
        ("CHF", "12", "CHF 12.00"),
        ("SEK", "439", "439,00 kr"),
        ("NOK", "439", "439,00 kr"),
        ("DKK", "279", "279,00 kr."),
        ("MXN", "739", "MX$ 739.00"),
        ("INR", "3399", "₹3,399"),
        ("TRY", "1599.99", "₺1.599,99"),
        ("CNY", "288", "CN¥288.00"),
        ("PLN", "159.99", "159,99 zł"),
        ("CZK", "999", "999 Kč"),
    ])
    func formatsEachCurrencyStyle(example: (code: String, amount: String, text: String)) {
        #expect(CurrencyFormat.format(PricingFixtures.money(example.amount), currency: example.code) == example.text)
    }

    @Test func groupsThousandsWithTheCurrencysSeparator() {
        #expect(CurrencyFormat.format(PricingFixtures.money("1234567.891"), currency: "EUR") == "1.234.567,89 €")
        #expect(CurrencyFormat.format(1234, currency: "CHF") == "CHF 1’234.00")
        #expect(CurrencyFormat.format(12345, currency: "SEK") == "12 345,00 kr")
        #expect(CurrencyFormat.format(PricingFixtures.money("1999.99"), currency: "EGP") == "EGP 1,999.99")
    }

    @Test func roundsToTheCurrencysDecimals() {
        #expect(CurrencyFormat.format(PricingFixtures.money("109.95"), currency: "BRL") == "R$ 109,95")
        #expect(CurrencyFormat.format(PricingFixtures.money("164.925"), currency: "BRL") == "R$ 164,93")
        #expect(CurrencyFormat.format(PricingFixtures.money("3299.5"), currency: "JPY") == "¥3,300")
    }

    @Test func negativeAmountsUseATrueMinus() {
        #expect(CurrencyFormat.format(PricingFixtures.money("-12.5"), currency: "USD") == "−$12.50")
        #expect(CurrencyFormat.format(PricingFixtures.money("-0.001"), currency: "USD") == "$0.00")
    }

    @Test func wholeUnitsDropTheDecimals() {
        #expect(CurrencyFormat.usd.formatWhole(PricingFixtures.money("79.96")) == "$80")
        #expect(CurrencyFormat.usd.formatWhole(PricingFixtures.money("39.98")) == "$40")
        #expect(CurrencyFormat.usd.formatWhole(17646) == "$17,646")
    }

    @Test func unknownCurrenciesFallBackToTheirCode() {
        let format = CurrencyFormat.forCurrency("XXX")
        #expect(format.code == "XXX")
        #expect(format.format(5) == "XXX 5.00")
    }

    @Test func catalogHasOneFormatPerCurrency() {
        #expect(Set(CurrencyFormat.all.map(\.code)).count == CurrencyFormat.all.count)
        #expect(CurrencyFormat.forCurrency("USD") == .usd)
    }
}
