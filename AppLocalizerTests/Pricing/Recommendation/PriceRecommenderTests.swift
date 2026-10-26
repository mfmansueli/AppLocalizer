//
//  PriceRecommenderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The suggestions on the prototype's sample data (design README, section 11).
@Suite("PriceRecommender")
struct PriceRecommenderTests {
    private let sample = PricingFixtures.sample

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    private func recommendation(_ code: String, canReadSales: Bool = true) throws -> Recommendation {
        try sample.recommendation(for: PricingFixtures.territory(code), subscription: .annual, canReadSales: canReadSales)
    }

    @Test func brazilFeelsTwiceTheUSPriceWithFewStarts() throws {
        let brazil = try recommendation("BR")
        #expect(brazil.price.customerPrice == money("109.90"))
        #expect(brazil.currentPrice == money("219.90"))
        #expect(brazil.confidence == .medium)
        #expect(brazil.reason == "Feels like 2.0× the US price · many page views, few starts")
        #expect(brazil.feelsLikeText == "$80")
        #expect(brazil.feelsLikeSuggestedText == "$40")
        #expect(brazil.ratioText == "2.0×")
        #expect(brazil.suggestedRatioText == "1.0×")
        #expect(brazil.factor == money("0.5"))
        #expect(brazil.likelyHoldsPeopleBack)
        #expect(brazil.summary == "R$ 219,90 equalized × 0.5 = R$ 109,95 → above floor → R$ 109,90")
        #expect(brazil.basis == [
            "Purchasing power: World Bank 2024 price level 0.50",
            "Your sales, last 28 days: 4,800 page views · 31 starts · 0.65% (US 2.39%)",
        ])
    }

    @Test func mexicosEarlierCutGivesHighConfidence() throws {
        let mexico = try recommendation("MX")
        #expect(mexico.currentPrice == 549)
        #expect(mexico.price.customerPrice == 439)
        #expect(mexico.confidence == .high)
        #expect(mexico.reason == "Feels like 1.2× the US price")
        #expect(!mexico.isHolding)
        #expect(mexico.basis.last == "Earlier change, Jul 14, 2026: MX$ 739.00 → MX$ 549.00, starts 16 → 22 in 28 days")
    }

    @Test func turkiyeHoldsBecauseTheLastCutDidNotLiftStarts() throws {
        let turkiye = try recommendation("TR")
        #expect(turkiye.isHolding)
        #expect(turkiye.isUnchanged)
        #expect(turkiye.price.customerPrice == money("1199.99"))
        #expect(turkiye.confidence == .high)
        #expect(turkiye.reason == "Last cut didn’t lift starts · holding")
        #expect(turkiye.summary == "Holding at ₺1.199,99")
        #expect(!turkiye.likelyHoldsPeopleBack)
        #expect(turkiye.basis[1].hasSuffix(", too few to count"))
    }

    @Test func japanConvertsWellSoTheStepIsHalved() throws {
        let japan = try recommendation("JP")
        #expect(japan.isSoftStep)
        #expect(japan.price.customerPrice == 4800)
        #expect(japan.reason == "Feels like 1.7× the US price · converts well, smaller step")
        #expect(japan.calculation?.multiplier == money("0.8"))
    }

    @Test func indiaIsHeldAtTheFloor() throws {
        let india = try recommendation("IN")
        #expect(india.price.customerPrice == 1049)
        #expect(india.reason == "Feels like 2.9× the US price · many page views, few starts · held at the floor")
        #expect(india.feelsLikeText == "$118")
    }

    @Test func pricesAtOrBelowTheLocalLevelStay() throws {
        let switzerland = try recommendation("CH")
        #expect(switzerland.isUnchanged)
        #expect(switzerland.reason == "Already below the local price level")
        #expect(switzerland.confidence == .low)
        let norway = try recommendation("NO")
        #expect(norway.reason == "Already matches local purchasing power")
        #expect(norway.basis.last == "Your sales: too few in this territory to count")
    }

    @Test func withoutSalesOnlyPurchasingPowerCounts() throws {
        let brazil = try recommendation("BR", canReadSales: false)
        #expect(brazil.price.customerPrice == money("109.90"))
        #expect(brazil.confidence == .low)
        #expect(brazil.reason == "Feels like 2.0× the US price")
        #expect(brazil.basis.last == "Sales: this key’s role can’t read Sales and Trends")
        let turkiye = try recommendation("TR", canReadSales: false)
        #expect(!turkiye.isHolding)
        #expect(turkiye.confidence == .low)
    }

    @Test func baseTerritoryHasNoSuggestion() throws {
        let unitedStates = try recommendation("US")
        #expect(unitedStates.isBaseTerritory)
        #expect(unitedStates.isUnchanged)
        #expect(unitedStates.confidence == nil)
        #expect(unitedStates.calculation == nil)
        #expect(unitedStates.reason == "Base territory")
        #expect(unitedStates.feelsLikeText == "$40")
    }

    @Test func territoriesWithoutWorldBankDataSayWhereTheFactorCameFrom() throws {
        let anguilla = try recommendation("AI")
        #expect(anguilla.basis.first == "Purchasing power: World Bank 2024 price level 0.55 (region median, no World Bank data)")
    }

    @Test func feelsLikeDividesByMultiplierAndFactor() {
        let feels = PriceRecommender.feelsLike(money("219.9"), equalizationMultiplier: money("5.5"), factor: money("0.5"))
        #expect(feels.rounded(scale: 2) == money("79.96"))
        #expect(PriceRecommender.feelsLike(10, equalizationMultiplier: 0, factor: 1) == 10)
    }

    @Test func confidenceBarsAndTitles() {
        #expect(RecommendationConfidence.allCases.map(\.bars) == [1, 2, 3])
        #expect(RecommendationConfidence.medium.title == "Medium confidence")
        #expect(RecommendationConfidence.low < .high)
    }

    @Test func sampleHas146TerritoriesLikelyHoldingPeopleBack() {
        let held = sample.catalog.territories.count {
            sample.recommendation(for: $0, subscription: .annual).likelyHoldsPeopleBack
        }
        #expect(held == 146)
    }
}
