//
//  ProposePricesToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("propose_prices")
struct ProposePricesToolTests {
    private typealias Fixtures = MCPPricingFixtures
    private let changes = ChangeQueue()

    private func propose(
        _ arguments: [String: JSONValue],
        product: String = Fixtures.annual,
        modes: [StoreApp.ID: PricingMode] = [Fixtures.tempo: .keepPrices]
    ) async throws -> MCPToolOutcome {
        var arguments = arguments
        if arguments["appId"] == nil { arguments["appId"] = .string(Fixtures.lumen) }
        if arguments["productId"] == nil { arguments["productId"] = .string(product) }
        return try await Fixtures.call(ProposePricesTool(), arguments, changes: changes, modes: modes)
    }

    private func item(_ territory: String, _ price: JSONValue) -> JSONValue {
        ["territory": .string(territory), "price": price]
    }

    // MARK: - Queued

    @Test func aPricePointIsQueuedAsTheAssistants() async throws {
        let outcome = try await propose(["territory": "BRA", "price": .double(109.9)])

        #expect(outcome.result == [
            "territory": "BRA", "price": .double(109.9), "status": "queued", "changeId": .string(Fixtures.changeID("BRA")),
        ])
        let change = try #require(changes.change(id: Fixtures.changeID("BRA")))
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(change.oldValue == "R$ 219,90")
        #expect(change.newValue == "R$ 109,90")
        #expect(change.requests.count == 1)
        #expect(!change.restoreRequests.isEmpty)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Lumen Plus Annual · Brazil", outcome: .proposed)])
    }

    @Test func pricesMayBeStringsAndTerritoriesTwoLetterCodes() async throws {
        let outcome = try await propose(["territory": "br", "price": "109,90"])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["territory"] == "BRA")
    }

    @Test func aProposalFollowsTheSubscriptionsSchedule() async throws {
        let matrix = try await PricingModelFixtures.matrix(queue: changes)
        await matrix.applySuggestion(to: ["IND"])
        let schedule = PriceSchedule(startDay: "2026-11-02")
        matrix.setSchedule(schedule)

        _ = try await propose(["territory": "BRA", "price": .double(109.9)])

        let change = try #require(changes.change(id: Fixtures.changeID("BRA")))
        #expect(PriceSchedule(change: change) == schedule)
        #expect(change.groupNote == schedule.note)
    }

    @Test func thePersonsOwnPriceKeepsBothVersions() async throws {
        try changes.upsert(Fixtures.personsChange("BRA", to: "99.90"))

        let outcome = try await propose(["territory": "BRA", "price": .double(109.9)])

        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["note"] != nil)
        let change = try #require(changes.change(id: Fixtures.changeID("BRA")))
        #expect(change.source == .you)
        #expect(change.newValue == "R$ 99,90")
        #expect(change.alternative?.source == .assistant(client: "Claude Code"))
        #expect(change.alternative?.newValue == "R$ 109,90")
    }

    // MARK: - Unchanged

    @Test func todaysPriceIsUnchanged() async throws {
        let outcome = try await propose(["territory": "BRA", "price": .double(219.9)])
        #expect(outcome.result["status"] == "unchanged")
        #expect(outcome.result["note"] == "That’s already today’s price in App Store Connect; nothing was queued.")
        #expect(changes.changes.isEmpty)
        #expect(outcome.logLines.first?.outcome == .read)
    }

    @Test func todaysPriceWithdrawsTheAssistantsProposal() async throws {
        _ = try await propose(["territory": "BRA", "price": .double(109.9)])
        #expect(changes.changes.count == 1)

        let outcome = try await propose(["territory": "BRA", "price": .double(219.9)])

        #expect(outcome.result["status"] == "unchanged")
        #expect(outcome.result["note"] == "That’s today’s price, so your earlier proposal for this territory was withdrawn.")
        #expect(changes.changes.isEmpty)
    }

    @Test func todaysPriceClearsOnlyTheAssistantsVersion() async throws {
        try changes.upsert(Fixtures.personsChange("BRA", to: "99.90"))
        _ = try await propose(["territory": "BRA", "price": .double(109.9)])

        _ = try await propose(["territory": "BRA", "price": .double(219.9)])

        let change = try #require(changes.change(id: Fixtures.changeID("BRA")))
        #expect(change.source == .you)
        #expect(change.newValue == "R$ 99,90")
        #expect(change.alternative == nil)
    }

    @Test func todaysPriceLeavesThePersonsChange() async throws {
        try changes.upsert(Fixtures.personsChange("BRA", to: "99.90"))
        _ = try await propose(["territory": "BRA", "price": .double(219.9)])
        #expect(changes.change(id: Fixtures.changeID("BRA"))?.source == .you)
    }

    @Test func thePriceAlreadyWaitingIsUnchanged() async throws {
        try changes.upsert(Fixtures.personsChange("BRA", to: "109.90", source: .suggestion))

        let outcome = try await propose(["territory": "BRA", "price": .double(109.9)])

        #expect(outcome.result["status"] == "unchanged")
        #expect(changes.change(id: Fixtures.changeID("BRA"))?.source == .suggestion)
    }

    // MARK: - Refused

    @Test func aPriceBetweenPointsNamesTheNearestOnes() async throws {
        let outcome = try await propose(["territory": "BRA", "price": 112])

        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"] == "R$ 112,00 isn’t a price point in Brazil. Nearest: R$ 110,00 or R$ 114,90. Propose one of them.")
        #expect(outcome.result["nearest"] == [110, .double(114.9)])
        #expect(changes.changes.isEmpty)
        #expect(outcome.logLines.first?.outcome == .refused)
        #expect(outcome.logLines.first?.reason == outcome.result["reason"]?.stringValue)
    }

    @Test func anUnknownTerritoryIsRefused() async throws {
        let outcome = try await propose(["territory": "Atlantis", "price": 10])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["territory"] == "Atlantis")
        #expect(outcome.result["reason"]?.stringValue?.hasPrefix("“Atlantis” isn’t a territory Lumen Plus Annual is sold in.") == true)
        #expect(outcome.logLines.first?.target == "Lumen Journal · Lumen Plus Annual · Atlantis")
    }

    @Test func anUnknownProductIsRefused() async throws {
        let outcome = try await propose(["territory": "BRA", "price": .double(109.9)], product: "Gold")
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.hasPrefix("Lumen Journal has no product “Gold”.") == true)
        #expect(changes.changes.isEmpty)
    }

    @Test func inAppPurchasesAreRefused() async throws {
        let outcome = try await propose(["territory": "BRA", "price": .double(109.9)], product: Fixtures.lifetime)
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.contains("in-app purchase") == true)
        #expect(changes.changes.isEmpty)
    }

    @Test func keepMyPricesRefusesEveryPrice() async throws {
        let prices: [JSONValue] = [item("BRA", .double(59.9)), item("USA", .double(19.99))]
        let outcome = try await propose(["appId": .string(Fixtures.tempo), "prices": .array(prices)], product: "tempo.pro.annual")

        let results = try #require(outcome.result["results"]?.arrayValue)
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0["status"] == "refused" })
        #expect(results.allSatisfy { $0["reason"]?.stringValue?.contains("Keep my prices") == true })
        #expect(outcome.result["refused"] == 2)
        #expect(changes.changes.isEmpty)
        #expect(outcome.logLines.map(\.outcome) == [.refused, .refused])
    }

    @Test func keepMyPricesRefusesEvenAnUnknownProduct() async throws {
        let outcome = try await propose(["territory": "BRA", "price": .double(109.9)], product: "Gold", modes: [Fixtures.lumen: .keepPrices])
        #expect(outcome.result["reason"]?.stringValue?.contains("Keep my prices") == true)
    }

    // MARK: - Batch

    @Test func aBatchReportsEachPrice() async throws {
        let prices: [JSONValue] = [item("BRA", .double(109.9)), item("BRA", 112), item("USA", .double(39.99)), item("XX", 1)]
        let outcome = try await propose(["prices": .array(prices)])

        let statuses = try #require(outcome.result["results"]?.arrayValue).map { $0["status"]?.stringValue }
        #expect(statuses == ["queued", "refused", "unchanged", "refused"])
        #expect(outcome.result["queued"] == 1)
        #expect(outcome.result["unchanged"] == 1)
        #expect(outcome.result["refused"] == 2)
        #expect(outcome.logLines.map(\.outcome) == [.proposed, .refused, .read, .refused])
        #expect(changes.changes.count == 1)
    }

    // MARK: - Arguments

    @Test func theProductIsRequired() async throws {
        await #expect(throws: MCPToolError.invalidArgument(name: "productId", expected: "a string")) {
            try await Fixtures.call(ProposePricesTool(), ["appId": .string(Fixtures.lumen), "territory": "BRA", "price": .double(109.9)])
        }
    }

    @Test func aTerritoryAndPriceOrAListAreRequired() async throws {
        await #expect(throws: MCPToolError.invalidArgument(name: "territory", expected: "a string")) {
            try await propose([:])
        }
        await #expect(throws: MCPToolError.invalidArgument(name: "price", expected: "a positive price in the territory’s currency, e.g. 109.9")) {
            try await propose(["territory": "BRA", "price": -3])
        }
    }

    @Test func theListMustHoldObjects() async throws {
        let expected = MCPToolError.invalidArgument(name: "prices", expected: "a non-empty list of {territory, price} objects")
        await #expect(throws: expected) { try await propose(["prices": .array([])]) }
        await #expect(throws: expected) { try await propose(["prices": .array([.string("BRA 109.9")])]) }
        await #expect(throws: MCPToolError.self) { try await propose(["prices": "BRA"]) }
    }

    @Test func theToolProposesPrices() {
        #expect(ProposePricesTool().definition.proposalKind == .prices)
        #expect(GetPricesTool().definition.isReadOnly)
        #expect(GetPricePointsTool().definition.isReadOnly)
        #expect(MCPToolbox.standard.toolNames.isSuperset(of: ["get_prices", "get_price_points", "propose_prices"]))
    }
}
#endif
