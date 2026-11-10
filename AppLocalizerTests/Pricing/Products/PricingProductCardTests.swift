//
//  PricingProductCardTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A product's card on Pricing's Prices page, read from Lumen Plus Annual's
/// sample matrix: how its prices are set, its open price suggestion, and
/// what Keep my prices, Dismiss and accepting do to it.
@MainActor
@Suite("Pricing product card")
struct PricingProductCardTests {
    private func card(_ matrix: PriceMatrixModel, isDismissed: Bool = false) -> PricingProductCard {
        PricingProductCard.make(product: matrix.product, rows: matrix.rows, showsSuggestions: matrix.showsSuggestions, isDismissed: isDismissed)
    }

    @Test func everyCountryIsCountedOnce() async throws {
        let matrix = try await PricingModelFixtures.matrix()
        let card = card(matrix)
        #expect(card.territoryCount == matrix.rows.count)
        #expect(card.equalizedCount + card.customCount + card.suggestedCount + card.queuedCount == card.territoryCount)
        #expect(card.prices.count == matrix.rows.count)
        #expect(card.legend.hasPrefix("\(matrix.rows.count) countries and regions"))
        #expect(card.kindText == "Subscription · \(matrix.product.durationText)")
        #expect(card.baseTerritoryText == "in the United States")
        #expect(card.basePrice != nil)
    }

    @Test func theRecommendedStrategyLowersPricesInTheMostVisitedCountriesFirst() async throws {
        let matrix = try await PricingModelFixtures.matrix()
        let card = card(matrix)
        let suggestion = try #require(card.suggestion)
        #expect(suggestion.count == card.suggestedCount)
        #expect(suggestion.title.hasPrefix("Lower the price in"))
        #expect(suggestion.countries.count == min(PricingProductCard.listedCountryCount, suggestion.count))
        #expect(suggestion.moreCount == suggestion.count - suggestion.countries.count)
        let views = suggestion.countries.map { id in matrix.rows.first { $0.id == id.id }?.pageViews ?? 0 }
        #expect(views == views.sorted(by: >))
        #expect(suggestion.countries.allSatisfy { $0.change.hasPrefix("−") })
        let listed = try #require(suggestion.countries.first)
        #expect(card.prices[listed.id]?.next == listed.suggested)
    }

    @Test func aDismissedSuggestionOrKeepMyPricesShowsNone() async throws {
        let matrix = try await PricingModelFixtures.matrix()
        let dismissed = card(matrix, isDismissed: true)
        #expect(dismissed.suggestion == nil)
        #expect(dismissed.suggestedCount == 0)
        #expect(dismissed.prices.values.allSatisfy { $0.next == nil })

        let kept = try await PricingModelFixtures.matrix(mode: .keepPrices)
        #expect(card(kept).suggestion == nil)
    }

    @Test func acceptedPricesWaitAsNotPushed() async throws {
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        let card = card(matrix)
        #expect(card.suggestion == nil)
        #expect(card.hasQueuedChanges)
        #expect(card.legend.contains("\(card.queuedCount) not pushed"))
        let brazil = try #require(card.prices["BRA"])
        #expect(brazil.next != nil)
    }
}
#endif
