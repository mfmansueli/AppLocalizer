//
//  PricingViewModelProductsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Pricing's Prices page on Lumen Journal's sample products: every product
/// is read for its card, and Accept, Accept All, Undo, Dismiss and Restore
/// change the queue and the cards. Nothing is pushed.
@MainActor
@Suite("Pricing products page")
struct PricingViewModelProductsTests {
    private func loaded(queue: ChangeQueue = ChangeQueue(), mode: PricingMode = .showSuggestions) async -> PricingViewModel {
        let model = await PricingModelFixtures.viewModel(queue: queue, mode: mode)
        await model.productsTask?.value
        return model
    }

    private func pricingChanges(_ queue: ChangeQueue) -> [PendingChange] {
        queue.changes(for: PricingModelFixtures.appID, section: .subscriptionPricing)
    }

    @Test func everyProductGetsACardAndTheOpenOnesAreCounted() async {
        let model = await loaded()
        #expect(model.areProductsLoaded)
        let cards = model.productCards
        #expect(!cards.isEmpty)
        #expect(cards.map(\.id) == (model.catalog?.products ?? []).map(\.id).filter { model.productMatrices[$0] != nil })
        #expect(model.openPriceSuggestionCount == cards.count { $0.suggestion != nil })
        #expect(model.openPriceSuggestionCount > 0)
        #expect(model.territoryCount == cards.first?.territoryCount)
        #expect(model.payTerritories.first?.alpha2 == "US")
    }

    @Test func acceptingOneQueuesItsPricesAndUndoTakesThemBack() async throws {
        let queue = ChangeQueue()
        let model = await loaded(queue: queue)
        let open = try #require(model.productCards.first { $0.suggestion != nil })
        let before = model.openPriceSuggestionCount

        await model.acceptPriceSuggestion(productID: open.id)
        #expect(model.toast?.text == "Prices for \(open.product.name) accepted. They’re in Review & Push.")
        #expect(model.toast?.canUndo == true)
        #expect(!pricingChanges(queue).isEmpty)
        #expect(model.card(for: open.product)?.suggestion == nil)
        #expect(model.openPriceSuggestionCount == before - 1)

        model.undoToast()
        #expect(model.toast == nil)
        #expect(pricingChanges(queue).isEmpty)
        #expect(model.card(for: open.product)?.suggestion != nil)
    }

    @Test func acceptAllAcceptsEveryOpenSuggestion() async {
        let queue = ChangeQueue()
        let model = await loaded(queue: queue)
        let count = model.openPriceSuggestionCount
        await model.acceptAllPriceSuggestions()
        #expect(model.openPriceSuggestionCount == 0)
        #expect(!pricingChanges(queue).isEmpty)
        let expected = count == 1 ? "accepted. They’re in Review & Push." : "Accepted prices for \(count) products. They’re in Review & Push."
        #expect(model.toast?.text.hasSuffix(expected) == true)
    }

    @Test func aDismissedSuggestionStaysAwayUntilRestored() async throws {
        let model = await loaded()
        let open = try #require(model.productCards.first { $0.suggestion != nil })
        model.toggleCountries(productID: open.id)
        #expect(model.expandedProductID == open.id)

        model.dismissPriceSuggestion(productID: open.id)
        #expect(model.card(for: open.product)?.suggestion == nil)
        #expect(model.hasDismissedPriceSuggestions)
        #expect(model.expandedProductID == nil)

        model.restoreDismissedPriceSuggestions()
        #expect(model.card(for: open.product)?.suggestion != nil)
        #expect(!model.hasDismissedPriceSuggestions)
    }

    @Test func keepMyPricesHasNothingToSuggest() async {
        let model = await loaded(mode: .keepPrices)
        #expect(model.openPriceSuggestionCount == 0)
        #expect(model.productCards.allSatisfy { $0.suggestion == nil })
    }

    @Test func editPricesOpensTheMatrixAndBackReturnsToTheCards() async throws {
        let model = await loaded()
        let product = try #require(model.catalog?.products.first)
        await model.openDetails(productID: product.id)
        #expect(model.showsProductDetails)
        #expect(model.selectedProductID == product.id)
        model.showProducts()
        #expect(!model.showsProductDetails)
    }

    @Test func theBannerSaysHowManyProducts() async {
        let model = await loaded()
        let count = model.openPriceSuggestionCount
        let expected = count == 1
            ? "Price suggestions for 1 product. See it below, or accept it here."
            : "Price suggestions for \(count) products. See each one below, or accept them together."
        #expect(model.priceSuggestionsBannerText == expected)
    }
}
#endif
