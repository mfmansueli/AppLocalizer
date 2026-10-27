//
//  ResultsEvaluatorTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ResultsEvaluator")
struct ResultsEvaluatorTests {
    private func window(_ starts: Int, _ proceeds: Decimal, views: Int = 1000) -> SalesWindow {
        SalesWindow(pageViews: views, starts: starts, proceeds: proceeds)
    }

    // MARK: - Verdicts

    @Test func moreStartsAndProceedsIsBetter() {
        #expect(ResultsEvaluator.verdict(before: window(31, 1053), after: window(68, 1155)) == .better)
        #expect(ResultsEvaluator.verdict(before: window(31, 1053), after: window(68, 1053)) == .better)
    }

    @Test func moreStartsLessProceedsIsNeutral() {
        let verdict = ResultsEvaluator.verdict(before: window(92, 2986), after: window(98, 2704))
        #expect(verdict == .moreStartsLessProceeds)
        #expect(!verdict.offersRestore)
        #expect(verdict.title == "More starts, less proceeds")
    }

    @Test func noMoreStartsIsWorseAndOffersRestore() {
        let verdict = ResultsEvaluator.verdict(before: window(37, 1144), after: window(34, 841))
        #expect(verdict == .worse)
        #expect(verdict.offersRestore)
        #expect(ResultsEvaluator.verdict(before: window(20, 100), after: window(20, 200)) == .worse)
    }

    @Test func underTenStartsOnBothSidesIsTooLittleData() {
        #expect(ResultsEvaluator.verdict(before: window(9, 10), after: window(9, 10)) == .tooLittleData)
        #expect(!ResultVerdict.tooLittleData.hasEnoughData)
        #expect(ResultsEvaluator.verdict(before: window(6, 179), after: window(13, 120)) == .moreStartsLessProceeds)
    }

    // MARK: - Availability

    @Test func tooEarlyUntilDay28() {
        let push = PricingSampleData.pushDate
        let arrives = PricingSampleData.date("2026-11-23")
        #expect(ResultsEvaluator.availability(changedOn: push, now: push) == .tooEarly(day: 1, arrivesOn: arrives))
        let dayTen = PricingSampleData.date("2026-11-04")
        #expect(ResultsEvaluator.availability(changedOn: push, now: dayTen) == .tooEarly(day: 10, arrivesOn: arrives))
        #expect(ResultsEvaluator.availability(changedOn: push, now: PricingSampleData.date("2026-11-22")) == .tooEarly(day: 28, arrivesOn: arrives))
        #expect(ResultsEvaluator.availability(changedOn: push, now: arrives) == .ready)
        #expect(PricingText.date(arrives) == "Nov 23, 2026")
    }

    // MARK: - Summary

    @Test func summaryCountsOnlyTerritoriesWithEnoughData() {
        let brazil = PriceChangeResult(
            territory: Territory(id: "BRA", alpha2: "BR", name: "Brazil", region: .americas, currencyCode: "BRL", taxRate: 0, latitude: 0, longitude: 0),
            oldPrice: PricingFixtures.money("219.9"),
            newPrice: PricingFixtures.money("109.9"),
            before: window(31, 1000),
            after: window(68, 1100)
        )
        var quiet = brazil
        quiet.before = window(2, 50)
        quiet.after = window(3, 40)
        let summary = ResultsEvaluator.summarize([brazil, quiet])
        #expect(summary.territoryCount == 2)
        #expect(summary.countedCount == 1)
        #expect(summary.tooLittleDataCount == 1)
        #expect(summary.startsBefore == 31)
        #expect(summary.startsAfter == 68)
        #expect(summary.startsChange.percentText == "+119%")
        #expect(summary.proceedsChange.percentText == "+10%")
        #expect(summary.breakdownText == "1 better · 0 worse · 1 too few sales to tell")
        #expect(brazil.startsChange?.percentText == "+119%")
        #expect(brazil.priceChange.percentText == "−50%")
    }

    @Test func sampleResultsMatchThePrototype() {
        let results = PricingFixtures.sample.results()
        let summary = ResultsEvaluator.summarize(results)
        #expect(summary.territoryCount == 164)
        #expect(summary.countedCount == 17)
        #expect(summary.betterCount == 6)
        #expect(summary.worseCount == 3)
        #expect(summary.startsBefore == 566)
        #expect(summary.startsAfter == 739)
        #expect(summary.startsChange.percentText == "+31%")
        #expect(CurrencyFormat.usd.formatWhole(summary.proceedsBefore) == "$17,646")
        #expect(summary.proceedsChange.direction == .decrease)
        #expect(results.first?.territory.alpha2 == "IN")
        #expect(results.first { $0.territory.alpha2 == "JP" }?.verdict == .worse)
    }

    @Test func proceedsAreConvertedToDollars() throws {
        let brazil = try PricingFixtures.territory("BR")
        let proceeds = ResultsEvaluator.proceeds(starts: 10, price: 55, territory: brazil, commission: .smallBusiness)
        #expect(proceeds == PricingFixtures.money("85"))
    }

    @Test func conversionText() {
        #expect(window(31, 0, views: 4800).conversionText == "0.65%")
        #expect(window(0, 0, views: 0).conversionText == "—")
    }
}
