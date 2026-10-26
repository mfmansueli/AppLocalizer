//
//  GetPricesToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("get_prices")
struct GetPricesToolTests {
    private typealias Fixtures = MCPPricingFixtures

    private func territory(_ code: String, in outcome: MCPToolOutcome, product: Int = 0) throws -> JSONValue {
        let products = try #require(outcome.result["products"]?.arrayValue)
        let territories = try #require(products[product]["territories"]?.arrayValue)
        return try #require(territories.first { $0["territory"]?.stringValue == code })
    }

    @Test func readsEveryProductWithTheMode() async throws {
        let outcome = try await Fixtures.call(GetPricesTool(), ["appId": "Lumen Journal"])
        #expect(outcome.result["pricingMode"] == "showSuggestions")
        #expect(outcome.result["hint"]?.stringValue?.isEmpty == false)
        let products = try #require(outcome.result["products"]?.arrayValue)
        #expect(products.map { $0["productId"]?.stringValue } == [DebugPricingCatalog.lumenMonthlyID, Fixtures.annual, Fixtures.lifetime])
        #expect(products.map { $0["inAppPurchase"]?.boolValue } == [false, false, true])
        #expect(products.allSatisfy { $0["territories"]?.arrayValue?.count == 175 })
        #expect(outcome.logLines == [.init(target: "Lumen Journal · prices", outcome: .read)])
    }

    @Test func oneProductBySKU() async throws {
        let outcome = try await Fixtures.call(GetPricesTool(), ["appId": .string(Fixtures.lumen), "productId": "lumen.plus.annual"])
        let products = try #require(outcome.result["products"]?.arrayValue)
        #expect(products.count == 1)
        #expect(products[0]["name"] == "Lumen Plus Annual")
        #expect(products[0]["period"] == "1 year")
        #expect(products[0]["baseTerritory"] == "USA")
        #expect(outcome.logLines.first?.target == "Lumen Journal · Lumen Plus Annual")
    }

    @Test func eachTerritoryHasItsPriceProceedsAndSuggestion() async throws {
        let outcome = try await Fixtures.call(GetPricesTool(), ["appId": .string(Fixtures.lumen), "productId": .string(Fixtures.annual)])
        let brazil = try territory("BRA", in: outcome)
        #expect(brazil["currency"] == "BRL")
        #expect(brazil["price"] == .double(219.9))
        #expect(brazil["proceeds"]?.doubleValue ?? 0 > 0)
        #expect(brazil["suggested"] == .double(109.9))
        #expect(brazil["reason"]?.stringValue?.hasPrefix("Feels like 2.0× the US price") == true)
        #expect(brazil["queued"] == nil)
        let usa = try territory("USA", in: outcome)
        #expect(usa["price"] == .double(39.99))
        #expect(usa["suggested"] == nil)
        #expect(usa["reason"] == nil)
    }

    @Test func keepMyPricesShowsNoSuggestions() async throws {
        let arguments: [String: JSONValue] = ["appId": .string(Fixtures.lumen), "productId": .string(Fixtures.annual)]
        let outcome = try await Fixtures.call(GetPricesTool(), arguments, modes: [Fixtures.lumen: .keepPrices])
        #expect(outcome.result["pricingMode"] == "keepPrices")
        let territories = try #require(outcome.result["products"]?.arrayValue?.first?["territories"]?.arrayValue)
        let suggested = territories.compactMap { territory -> JSONValue? in territory["suggested"] ?? territory["reason"] }
        #expect(suggested.isEmpty)
    }

    @Test func queuedPricesAndCompetingVersionsShow() async throws {
        let changes = ChangeQueue()
        try changes.upsert(Fixtures.personsChange("BRA", to: "99.90"))
        try changes.upsert(Fixtures.personsChange("BRA", to: "109.90", source: .assistant(client: "Cursor")))

        let outcome = try await Fixtures.call(GetPricesTool(), ["appId": .string(Fixtures.lumen), "productId": .string(Fixtures.annual)], changes: changes)

        let brazil = try territory("BRA", in: outcome)
        #expect(brazil["queued"] == .double(99.9))
        #expect(brazil["queuedBy"] == "You")
        #expect(brazil["alternative"] == ["price": .double(109.9), "by": "Cursor"])
    }

    @Test func anUnknownProductNamesTheProducts() async throws {
        await #expect(throws: MCPToolError.notFound(
            "Lumen Journal has no product “Gold”. Use get_prices; its products are Lumen Plus Monthly (6450100001), "
                + "Lumen Plus Annual (6450100002), or Lumen Lifetime (6450100003)."
        )) {
            try await Fixtures.call(GetPricesTool(), ["appId": .string(Fixtures.lumen), "productId": "Gold"])
        }
    }

    @Test func theAppIsRequired() async throws {
        await #expect(throws: MCPToolError.invalidArgument(name: "appId", expected: "a string")) {
            try await Fixtures.call(GetPricesTool(), [:])
        }
    }
}
#endif
