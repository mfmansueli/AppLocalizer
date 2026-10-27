//
//  PriceFactorResolverTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The fallback chain on a small hand-written snapshot.
@Suite("PriceFactorResolver")
struct PriceFactorResolverTests {
    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    /// Big Mac covers three Americas territories; World Bank adds Mexico and
    /// two in Asia Pacific. Nothing covers Africa & Middle East.
    private var resolver: PriceFactorResolver {
        let snapshot = PricingFixtures.snapshot([
            .bigMac: ["USA": 1, "BRA": money("0.75"), "CHL": money("0.8")],
            .worldBank: ["USA": 1, "BRA": money("0.5"), "MEX": money("0.6"), "IND": money("0.25"), "IDN": money("0.32"), "GBR": money("0.88")],
        ])
        return PriceFactorResolver(snapshot: snapshot, catalog: PricingFixtures.catalog)
    }

    private var bigMacFirst: PricingStrategy {
        var strategy = PricingStrategy.recommended
        strategy.method = .priceIndex
        strategy.indexSource = .bigMac
        strategy.fallback = [.index(.worldBank), .regionMedian, .equalized]
        return strategy
    }

    private func resolve(_ code: String, _ strategy: PricingStrategy) throws -> ResolvedFactor {
        try resolver.resolve(PricingFixtures.territory(code), strategy: strategy)
    }

    @Test func chosenIndexComesFirst() throws {
        let brazil = try resolve("BR", bigMacFirst)
        #expect(brazil.factor == money("0.75"))
        #expect(brazil.provenance.kind == .index(.bigMac))
        #expect(!brazil.provenance.isFallback)
        #expect(brazil.provenance.badge == "Big Mac test")
    }

    @Test func fallbackIndexFillsTheGap() throws {
        let mexico = try resolve("MX", bigMacFirst)
        #expect(mexico.factor == money("0.6"))
        #expect(mexico.provenance.kind == .index(.worldBank))
        #expect(mexico.provenance.isFallback)
        #expect(mexico.provenance.label == "World Bank test")
    }

    @Test func regionMedianOfTheChosenIndexComesNext() throws {
        let canada = try resolve("CA", bigMacFirst)
        #expect(canada.factor == money("0.8"))
        #expect(canada.provenance.kind == .regionMedian(.bigMac))
        #expect(canada.provenance.isFallback)
        #expect(canada.provenance.badge == "Region median")
        #expect(canada.provenance.label == "region median")
    }

    @Test func regionMedianFallsBackToWorldBanksMedian() throws {
        let japan = try resolve("JP", bigMacFirst)
        #expect(japan.factor == money("0.32"))
        #expect(japan.provenance.kind == .regionMedian(.bigMac))
    }

    @Test func equalizedIsTheLastResort() throws {
        let kenya = try resolve("KE", bigMacFirst)
        #expect(kenya.factor == 1)
        #expect(kenya.provenance.kind == .equalized)
        #expect(kenya.provenance.isFallback)
        #expect(kenya.provenance.badge == "Equalized")
        #expect(kenya.provenance.label == "no data, equalized")
    }

    @Test func anEmptyChainEndsAtEqualized() throws {
        var strategy = bigMacFirst
        strategy.fallback = []
        #expect(strategy.resolutionChain == [.index(.bigMac)])
        #expect(try resolve("MX", strategy).provenance.kind == .equalized)
    }

    @Test func factorsAreRelativeToTheBaseTerritory() throws {
        var strategy = PricingStrategy.recommended(baseTerritoryID: "GBR")
        strategy.fallback = [.equalized]
        let brazil = try resolve("BR", strategy)
        #expect(brazil.factor == money("0.5") / money("0.88"))
        #expect(try resolve("GB", strategy).factor == 1)
    }

    @Test func aSourceWithoutTheBaseIsTakenAsRelativeToIt() {
        let snapshot = PricingFixtures.snapshot([.custom: ["BRA": money("0.55")]])
        let resolver = PriceFactorResolver(snapshot: snapshot, catalog: PricingFixtures.catalog)
        #expect(resolver.factor(.custom, territoryID: "BRA", baseTerritoryID: "USA") == money("0.55"))
        #expect(resolver.factor(.custom, territoryID: "MEX", baseTerritoryID: "USA") == nil)
        #expect(resolver.factor(.bigMac, territoryID: "BRA", baseTerritoryID: "USA") == nil)
    }

    @Test func bundledFallbacksMatchThePrototype() {
        let calculator = PricingFixtures.sample.calculator
        #expect(calculator.fallbackCount(strategy: .recommended) == 10)
        #expect(calculator.fallbackCount(strategy: bigMacFirst) == 101)
    }

    @Test func fallbackTitles() {
        #expect(FallbackStep.index(.worldBank).title(chosen: .bigMac) == "World Bank PPP price level")
        #expect(FallbackStep.regionMedian.title(chosen: .bigMac) == "Region median of Big Mac")
        #expect(FallbackStep.equalized.title(chosen: .bigMac) == "Apple’s equalized price")
    }
}
