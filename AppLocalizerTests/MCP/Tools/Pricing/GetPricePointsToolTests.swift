//
//  GetPricePointsToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("get_price_points")
struct GetPricePointsToolTests {
    private typealias Fixtures = MCPPricingFixtures

    private func arguments(territory: String, near: JSONValue? = nil) -> [String: JSONValue] {
        var arguments: [String: JSONValue] = ["appId": .string(Fixtures.lumen), "productId": .string(Fixtures.annual), "territory": .string(territory)]
        if let near { arguments["near"] = near }
        return arguments
    }

    private func pointList(_ outcome: MCPToolOutcome) throws -> [JSONValue] {
        try #require(outcome.result["points"]?.arrayValue)
    }

    @Test func pointsAroundTodaysPrice() async throws {
        let outcome = try await Fixtures.call(GetPricePointsTool(), arguments(territory: "br"))
        #expect(outcome.result["territory"] == "BRA")
        #expect(outcome.result["name"] == "Brazil")
        #expect(outcome.result["currency"] == "BRL")
        #expect(outcome.result["current"] == .double(219.9))
        let points = try pointList(outcome)
        #expect(points.count == 2 * GetPricePointsTool.pointsPerSide)
        let current = try #require(points.first { $0["current"] == true })
        #expect(current["price"] == .double(219.9))
        #expect(points.firstIndex(of: current) == GetPricePointsTool.pointsPerSide)
        let underPrice = points.allSatisfy { (point: JSONValue) -> Bool in
            (point["proceeds"]?.doubleValue ?? 0) < (point["price"]?.doubleValue ?? 0)
        }
        #expect(underPrice)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Lumen Plus Annual · Brazil", outcome: .read)])
    }

    @Test func pointsNearAnotherPrice() async throws {
        let outcome = try await Fixtures.call(
            GetPricePointsTool(),
            arguments(territory: "BRA", near: "112")
        )
        let prices = try pointList(outcome).compactMap { $0["price"] }
        #expect(prices.contains(.double(109.9)))
        #expect(prices.contains(.double(114.9)))
        #expect(outcome.result["near"] == 112)
    }

    @Test func anUnknownTerritoryIsNotFound() async throws {
        await #expect(throws: MCPToolError.self) {
            try await Fixtures.call(GetPricePointsTool(), arguments(territory: "Atlantis"))
        }
    }

    @Test func nearMustBeAPrice() async throws {
        await #expect(throws: MCPToolError.invalidArgument(name: "near", expected: "a positive price, e.g. 109.9")) {
            try await Fixtures.call(GetPricePointsTool(), arguments(territory: "BRA", near: "cheap"))
        }
    }

    @Test func theLadderEndsCutTheList() {
        let ladder = PricingFixtures.ladder(["1", "2", "3"])
        #expect(PricingFixtures.prices(GetPricePointsTool.points(in: ladder, around: 1)) == ["1", "2", "3"].map(PricingFixtures.money))
        #expect(GetPricePointsTool.points(in: ladder, around: 50).count == 3)
    }
}
#endif
