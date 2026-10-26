//
//  PricingStrategyTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PricingStrategy and PricingTiers")
struct PricingStrategyTests {
    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    @Test func recommendedIsWorldBankAtFullIntensity() {
        let strategy = PricingStrategy.recommended
        #expect(strategy.isRecommended)
        #expect(!strategy.isCustom)
        #expect(strategy.baseTerritoryID == "USA")
        #expect(strategy.indexSource == .worldBank)
        #expect(strategy.intensity == 1)
        #expect(strategy.floor == money("0.3"))
        #expect(strategy.ceiling == money("1.5"))
        #expect(strategy.discountOnly)
        #expect(!strategy.tiersEnabled)
        #expect(strategy.minimumProceeds == nil)
        #expect(strategy.rounding == .auto)
        #expect(strategy.resolutionChain == [.index(.worldBank), .regionMedian, .equalized])
    }

    @Test func anyEditTurnsRecommendedIntoACustomIndex() {
        var strategy = PricingStrategy.recommended
        strategy.customize { $0.floor = money("0.35") }
        #expect(strategy.method == .priceIndex)
        #expect(strategy.isCustom)
        #expect(strategy.floor == money("0.35"))
    }

    @Test func anEditThatChangesNothingStaysRecommended() {
        var strategy = PricingStrategy.recommended
        strategy.customize { $0.floor = money("0.3") }
        #expect(strategy.isRecommended)
    }

    @Test func pickingAnotherMethodKeepsIt() {
        var strategy = PricingStrategy.recommended
        strategy.customize { $0.method = .regionalTiers }
        #expect(strategy.method == .regionalTiers)
    }

    @Test func pickingRecommendedResetsEverythingButTheBase() {
        var strategy = PricingStrategy.recommended
        strategy.customize {
            $0.baseTerritoryID = "GBR"
            $0.intensity = money("0.5")
            $0.excludedTerritoryIDs = ["JPN"]
        }
        strategy.customize { $0.method = .recommended }
        #expect(strategy == .recommended(baseTerritoryID: "GBR"))
        #expect(strategy.excludedTerritoryIDs.isEmpty)
    }

    @Test func backToRecommendedKeepsTheBase() {
        var strategy = PricingStrategy.recommended(baseTerritoryID: "DEU")
        strategy.customize { $0.neverRaise = true }
        strategy.resetToRecommended()
        #expect(strategy.isRecommended)
        #expect(strategy.baseTerritoryID == "DEU")
        #expect(!strategy.neverRaise)
    }

    @Test func resolutionChainDoesNotRepeatTheChosenIndex() {
        var strategy = PricingStrategy.recommended
        strategy.indexSource = .bigMac
        strategy.fallback = [.index(.bigMac), .index(.worldBank), .equalized]
        #expect(strategy.resolutionChain == [.index(.bigMac), .index(.worldBank), .equalized])
    }

    @Test func exclusionsAndRegionMultipliers() {
        var strategy = PricingStrategy.recommended
        strategy.excludedTerritoryIDs = ["JPN"]
        #expect(strategy.isExcluded("JPN"))
        #expect(!strategy.isExcluded("BRA"))
        #expect(strategy.regionMultiplier(for: .europe) == money("0.9"))
        strategy.regionMultipliers[.europe] = nil
        #expect(strategy.regionMultiplier(for: .europe) == 1)
    }

    @Test func roundTripsThroughCodable() throws {
        var strategy = PricingStrategy.recommended
        strategy.customize {
            $0.indexSource = .imf
            $0.fallback = [.index(.bigMac), .regionMedian, .equalized]
            $0.minimumProceeds = 2
            $0.excludedTerritoryIDs = ["JPN", "KOR"]
            $0.rounding = .ninety
        }
        let data = try JSONEncoder().encode(strategy)
        #expect(try JSONDecoder().decode(PricingStrategy.self, from: data) == strategy)
    }

    @Test func methodTitles() {
        #expect(PricingMethod.allCases.map(\.title) == ["Recommended", "Apple equalization", "Price index", "Custom regional tiers"])
    }

    // MARK: - Tiers

    @Test(arguments: [("0.9", 0), ("0.85", 0), ("0.84", 1), ("0.65", 1), ("0.5", 2), ("0.45", 2), ("0.44", 3), ("0.1", 3)])
    func tiersBucketFactors(example: (factor: String, tier: Int)) {
        #expect(PricingTiers.standard.tierIndex(for: money(example.factor)) == example.tier)
    }

    @Test func tierSharesAndRules() {
        let tiers = PricingTiers.standard
        #expect((0..<4).map(tiers.share(forTier:)) == [1, money("0.8"), money("0.6"), money("0.4")])
        #expect(tiers.share(forTier: 9) == 1)
        #expect((0..<4).map(tiers.rule(forTier:)) == ["factor ≥ 0.85", "0.65–0.85", "0.45–0.65", "below 0.45"])
    }

    @Test func bundledTierCounts() {
        #expect(PricingFixtures.sample.calculator.tierCounts(strategy: .recommended) == [26, 26, 57, 66])
    }
}
