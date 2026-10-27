//
//  PricingSampleDataTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PricingSampleData")
struct PricingSampleDataTests {
    private let sample = PricingFixtures.sample

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    @Test func everyTerritoryHasALadder() {
        #expect(sample.ladders.count == 175)
        #expect(sample.ladders.values.allSatisfy { !$0.isEmpty })
        #expect(sample.baseTerritory?.id == "USA")
    }

    @Test func snapshotIncludesTheCustomIndex() {
        #expect(sample.snapshot.coverage(of: .custom) == 12)
        #expect(sample.snapshot.index(.custom)?.edition.label == "Imported Oct 20, 2026")
        #expect(sample.snapshot.coverage(of: .worldBank) == 165)
    }

    @Test(arguments: [
        ("US", "$39.99"), ("BR", "R$ 219,90"), ("DE", "39,99 €"), ("GB", "£35.99"), ("CA", "CA$ 55.99"), ("KR", "₩56,000"),
        ("JP", "¥6,000"), ("ID", "Rp 639.000"), ("CH", "CHF 40.00"), ("SE", "439,00 kr"), ("MX", "MX$ 739.00"), ("IN", "₹3,399"),
    ])
    func annualEqualizedPrices(example: (code: String, text: String)) throws {
        let territory = try PricingFixtures.territory(example.code)
        let equalized = sample.equalizedPrice(for: territory, subscription: .annual)
        #expect(CurrencyFormat.format(equalized, currency: territory.currencyCode) == example.text)
        #expect(sample.ladder(for: territory).point(at: equalized) != nil)
    }

    @Test func monthlyEqualizedPrices() throws {
        let brazil = try PricingFixtures.territory("BR")
        #expect(sample.equalizedPrice(for: brazil, subscription: .monthly) == money("26.90"))
        #expect(try sample.equalizedPrice(for: PricingFixtures.territory("US"), subscription: .monthly) == money("4.99"))
    }

    @Test func onlyThreeAnnualPricesDifferFromEqualized() throws {
        let custom = sample.catalog.territories.filter {
            sample.currentPrice(for: $0, subscription: .annual) != sample.equalizedPrice(for: $0, subscription: .annual)
        }
        #expect(custom.map(\.alpha2).sorted() == ["IN", "MX", "TR"])
        #expect(try sample.currentPrice(for: PricingFixtures.territory("TR"), subscription: .annual) == money("1199.99"))
        #expect(try sample.currentPrice(for: PricingFixtures.territory("MX"), subscription: .monthly) == 92)
    }

    @Test func salesExistForAnnualOnly() throws {
        let brazil = try PricingFixtures.territory("BR")
        #expect(sample.evidence(for: brazil, subscription: .annual).signal == SalesSignal(pageViews: 4800, starts: 31))
        #expect(sample.evidence(for: brazil, subscription: .monthly).signal == nil)
        #expect(sample.evidence(for: brazil, subscription: .annual, canReadSales: false) == .unavailable)
    }

    @Test func earlierChangesInMexicoAndTurkiye() throws {
        let mexico = try #require(sample.priorChange(for: PricingFixtures.territory("MX")))
        #expect(mexico.liftedStarts)
        #expect(mexico.previousPrice == 739)
        let turkiye = try #require(sample.priorChange(for: PricingFixtures.territory("TR")))
        #expect(!turkiye.liftedStarts)
        #expect(try sample.priorChange(for: PricingFixtures.territory("BR")) == nil)
    }

    @Test func subscribersPerTerritory() throws {
        #expect(try sample.subscribers(in: PricingFixtures.territory("US")) == 2140)
        #expect(try sample.subscribers(in: PricingFixtures.territory("BR")) == 0)
    }

    @Test func subscriptions() {
        #expect(PricingSampleSubscription.annual.basePrice == money("39.99"))
        #expect(PricingSampleSubscription.monthly.basePrice == money("4.99"))
        #expect(PricingSampleSubscription.lifetime.isInAppPurchase)
        #expect(!PricingSampleSubscription.annual.isInAppPurchase)
    }

    @Test func customIndexCSVMatchesTheCustomFactors() {
        let parsed = CustomIndexCSV.parse(PricingSampleData.customIndexCSV)
        #expect(parsed.factors == PricingSampleData.customIndex().levels)
    }
}
