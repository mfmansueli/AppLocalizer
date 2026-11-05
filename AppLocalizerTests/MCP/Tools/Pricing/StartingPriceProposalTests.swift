//
//  StartingPriceProposalTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `propose_prices` and `get_price_points` for a subscription without a
/// price in the United States yet: its US price is queued as its starting
/// price, equalized everywhere else by the push.
@MainActor
@Suite("propose_prices · starting price")
struct StartingPriceProposalTests {
    private typealias Fixtures = MCPPricingFixtures
    private let changes = ChangeQueue()

    /// Lumen Plus Annual, as if it had no prices in App Store Connect.
    private static var unpriced: DebugPricingServices {
        DebugPricingServices(sheetError: .noStartingPrice(productName: "Lumen Plus Annual"))
    }

    private static var product: PricingProduct {
        get throws { try #require(DebugPricingCatalog.catalog(for: Fixtures.lumen).product(id: Fixtures.annual)) }
    }

    /// Apple's US points for the subscription, as the tools read them.
    private static var usLadder: PricePointLadder {
        get throws {
            let sheet = try DebugPriceSheets.sheet(for: product, commission: .smallBusiness, canReadSales: true)
            return try #require(sheet.ladders["USA"])
        }
    }

    private var startingPriceID: PendingChange.ID {
        get throws { try NewSubscriptionChangeBuilder.startingPriceChangeID(appID: Fixtures.lumen, productID: Self.product.productID) }
    }

    private func propose(_ arguments: [String: JSONValue]) async throws -> MCPToolOutcome {
        var arguments = arguments
        arguments["appId"] = .string(Fixtures.lumen)
        arguments["productId"] = .string(Fixtures.annual)
        return try await Fixtures.call(ProposePricesTool(), arguments, changes: changes, pricing: Self.unpriced)
    }

    @Test func aUSPricePointIsQueuedAsTheStartingPrice() async throws {
        let point = try Self.usLadder.points[10].customerPrice
        let outcome = try await propose(["territory": "US", "price": MCPPriceValue.json(point)])

        let id = try startingPriceID
        #expect(outcome.result == ["territory": "USA", "price": MCPPriceValue.json(point), "status": "queued", "changeId": .string(id)])
        let change = try #require(changes.change(id: id))
        #expect(change.source == .assistant(client: Fixtures.client))
        #expect(change.oldValue == "No price")
        #expect(change.newValue.hasSuffix("equalized everywhere else"))
        let prices = try #require(change.requests.first.flatMap(SubscriptionStartingPrices.init))
        #expect(prices.subscriptionID == Fixtures.annual)
        #expect(prices.territoryID == "USA")
        #expect(prices.customerPrice == point)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Lumen Plus Annual · United States", outcome: .proposed)])
    }

    @Test func aUSPriceBetweenPointsNamesTheNearestOnes() async throws {
        let ladder = try Self.usLadder
        // Two neighbours with room between them ($2.99 and $3 have none).
        let index = try #require(ladder.points.indices.dropLast().first { ladder.points[$0 + 1].customerPrice - ladder.points[$0].customerPrice >= 0.5 })
        let below = ladder.points[index].customerPrice
        let above = ladder.points[index + 1].customerPrice
        let between = below + Decimal(25) / 100
        #expect(ladder.point(at: between) == nil)

        let outcome = try await propose(["territory": "USA", "price": MCPPriceValue.json(between)])

        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["nearest"] == [MCPPriceValue.json(below), MCPPriceValue.json(above)])
        #expect(outcome.result["reason"]?.stringValue?.contains("isn’t a price point in United States") == true)
        #expect(changes.changes.isEmpty)
    }

    @Test func otherTerritoriesWaitForTheUSPrice() async throws {
        let outcome = try await propose(["territory": "BRA", "price": .double(109.9)])

        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["territory"] == "BRA")
        #expect(outcome.result["reason"]?.stringValue?.contains("Propose territory USA") == true)
        #expect(changes.changes.isEmpty)
    }

    @Test func aBatchQueuesTheUSPriceAndRefusesTheRest() async throws {
        let point = try Self.usLadder.points[10].customerPrice
        let outcome = try await propose(["prices": [
            ["territory": "BRA", "price": .double(109.9)],
            ["territory": "United States", "price": MCPPriceValue.json(point)],
        ]])

        #expect(outcome.result["queued"] == 1)
        #expect(outcome.result["refused"] == 1)
        #expect(try changes.change(id: startingPriceID) != nil)
    }

    @Test func theSameStartingPriceAgainIsUnchanged() async throws {
        let point = try Self.usLadder.points[10].customerPrice
        _ = try await propose(["territory": "USA", "price": MCPPriceValue.json(point)])
        let outcome = try await propose(["territory": "USA", "price": MCPPriceValue.json(point)])

        #expect(outcome.result["status"] == "unchanged")
        #expect(changes.changes.count == 1)
    }

    @Test func anotherStartingPriceReplacesTheAssistantsEarlierOne() async throws {
        let ladder = try Self.usLadder
        _ = try await propose(["territory": "USA", "price": MCPPriceValue.json(ladder.points[10].customerPrice)])
        _ = try await propose(["territory": "USA", "price": MCPPriceValue.json(ladder.points[12].customerPrice)])

        #expect(changes.changes.count == 1)
        let change = try #require(changes.change(id: startingPriceID))
        #expect(change.requests.first.flatMap(SubscriptionStartingPrices.init)?.customerPrice == ladder.points[12].customerPrice)
    }

    @Test func keepMyPricesStillRefuses() async throws {
        let outcome = try await Fixtures.call(
            ProposePricesTool(),
            ["appId": .string(Fixtures.lumen), "productId": .string(Fixtures.annual), "territory": "USA", "price": .double(9.99)],
            changes: changes,
            modes: [Fixtures.lumen: .keepPrices],
            pricing: Self.unpriced
        )
        #expect(outcome.result["status"] == "refused")
        #expect(changes.changes.isEmpty)
    }

    // MARK: - get_price_points

    @Test func pricePointsListTheUSPointsWithoutACurrentPrice() async throws {
        let ladder = try Self.usLadder
        let near = ladder.points[10].customerPrice
        let outcome = try await Fixtures.call(
            GetPricePointsTool(),
            ["appId": .string(Fixtures.lumen), "productId": .string(Fixtures.annual), "territory": "USA", "near": MCPPriceValue.json(near)],
            pricing: Self.unpriced
        )

        #expect(outcome.result["territory"] == "USA")
        #expect(outcome.result["current"] == .null)
        #expect(outcome.result["note"] != nil)
        let prices = outcome.result["points"]?.arrayValue?.compactMap { $0["price"] } ?? []
        #expect(prices.count == 2 * GetPricePointsTool.pointsPerSide)
        #expect(prices.contains(MCPPriceValue.json(near)))
    }

    @Test func pricePointsElsewhereSayToSetTheUSPriceFirst() async throws {
        await #expect(throws: MCPToolError.self) {
            try await Fixtures.call(
                GetPricePointsTool(),
                ["appId": .string(Fixtures.lumen), "productId": .string(Fixtures.annual), "territory": "BRA"],
                pricing: Self.unpriced
            )
        }
    }
}
#endif
