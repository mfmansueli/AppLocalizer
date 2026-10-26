//
//  PricingDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Every Pricing scene opens a view, and the Results scenes' push and
/// sales are the prototype's.
@MainActor
@Suite("PricingDebugScenes")
struct PricingDebugScenesTests {
    @Test(arguments: PricingDebugScenes.ids)
    func everySceneHasAView(id: String) {
        #expect(PricingDebugScenes.view(for: id) != nil)
    }

    @Test func unknownIDsAreLeftToOtherSections() {
        #expect(PricingDebugScenes.view(for: "store-coverage") == nil)
    }

    @Test func theAnnualPushHoldsWhatApplyRecommendedQueues() async throws {
        let push = try #require(DebugPricingResults.annualPush())
        let matrix = try await PricingModelFixtures.matrix(follows: true)
        #expect(push.pushed.count == matrix.pendingCount)
        #expect(push.changedPrices)
        #expect(push.pushed.allSatisfy { !$0.restoreRequests.isEmpty })
        #expect(PricingText.date(push.date) == "Oct 26, 2026")
    }

    @Test func salesCoverEveryPushedTerritory() throws {
        let push = try #require(DebugPricingResults.annualPush())
        let sales = DebugPricingResults.salesComparison()
        let prefix = PriceChangeFactory.changeID(productID: DebugPricingCatalog.lumenAnnualID, territoryID: "")
        #expect(Set(push.pushed.map { String($0.id.dropFirst(prefix.count)) }) == Set(sales.keys))
    }

    @Test func subscribersAreKeyedByTerritoryID() {
        let subscribers = DebugPricingResults.subscribers()
        #expect(subscribers["USA"] == 2140)
        #expect(subscribers["BRA"] == nil)
    }

    @Test func otherProductsHaveNoOffersOrSales() async throws {
        let services = DebugPricingServices()
        let monthly = try #require(DebugPricingCatalog.catalog(for: PricingModelFixtures.appID).product(id: DebugPricingCatalog.lumenMonthlyID))
        #expect(try await services.offers(for: monthly).isEmpty)
        #expect(try await services.subscribers(for: monthly) == [:])
        #expect(try await services.salesComparison(for: monthly, territoryIDs: ["BRA"], changedOn: .now) == [:])
        let annual = try PricingModelFixtures.annual()
        #expect(try await DebugPricingServices(canReadSales: false).salesComparison(for: annual, territoryIDs: ["BRA"], changedOn: .now) == nil)
    }
}
#endif
