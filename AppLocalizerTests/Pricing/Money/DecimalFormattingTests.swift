//
//  DecimalFormattingTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("Decimal formatting and PricingText")
struct DecimalFormattingTests {
    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    @Test func roundsHalfAwayFromZero() {
        #expect(money("2.345").rounded(scale: 2) == money("2.35"))
        #expect(money("-2.345").rounded(scale: 2) == money("-2.35"))
        #expect(money("2.344").rounded(scale: 2) == money("2.34"))
        #expect(money("2.349").rounded(scale: 2, mode: .down) == money("2.34"))
    }

    @Test func fixedPadsAndTrimmedDropsZeros() {
        #expect(money("0.5").fixed(2) == "0.50")
        #expect(money("5").fixed(1) == "5.0")
        #expect(money("0.8").fixed(3) == "0.800")
        #expect(money("0.800").trimmed(maxPlaces: 3) == "0.8")
        #expect(money("1.000").trimmed(maxPlaces: 3) == "1")
        #expect(money("0.976").trimmed(maxPlaces: 2) == "0.98")
    }

    @Test func percentTextIsTheShareTimesAHundred() {
        #expect(money("0.3").percentText == "30")
        #expect(money("0.325").percentText == "32.5")
        #expect(money("1.5").percentText == "150")
    }

    @Test func exactDoublesReadThroughTheirShortestDescription() {
        #expect(Decimal(exactly: 0.85) == money("0.85"))
        #expect(Decimal(exactly: 5.5) == money("5.5"))
        #expect(Decimal(exactly: 0.95).doubleValue == 0.95)
    }

    @Test func groupedAndPercent() {
        #expect(PricingText.grouped(4800) == "4,800")
        #expect(PricingText.grouped(21400) == "21,400")
        #expect(PricingText.percent(31.0 / 4800) == "0.65%")
        #expect(PricingText.percent(512.0 / 21400) == "2.39%")
        #expect(PricingText.percent(0.5, places: 0) == "50%")
    }

    @Test func ratiosRoundHalvesUp() {
        #expect(PricingText.ratio(money("1.9996")) == "2.0×")
        #expect(PricingText.ratio(money("1.25")) == "1.3×")
        #expect(PricingText.ratio(1) == "1.0×")
    }

    @Test func signedPercentUsesATrueMinus() {
        #expect(PricingText.signedPercent(-50) == "−50%")
        #expect(PricingText.signedPercent(18) == "+18%")
        #expect(PricingText.signedPercent(0) == "0%")
    }

    @Test func datesAreWrittenInGMT() {
        #expect(PricingText.date(PricingSampleData.date("2026-07-14")) == "Jul 14, 2026")
        #expect(PricingText.date(PricingSampleData.date("2026-11-23")) == "Nov 23, 2026")
    }

    @Test func exchangeRatesConvertToDollars() {
        let rates = ExchangeRates.approximate
        #expect(rates.dollars(55, currency: "BRL") == 10)
        #expect(rates.dollars(money("39.99"), currency: "USD") == money("39.99"))
        #expect(rates.dollars(10, currency: "XXX") == nil)
    }
}
