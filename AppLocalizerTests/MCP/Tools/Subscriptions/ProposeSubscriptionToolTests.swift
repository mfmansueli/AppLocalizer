//
//  ProposeSubscriptionToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `get_subscriptions` and `propose_subscription`: what an app sells, and an
/// assistant's new subscription queued as one change, or refused with
/// App Store Connect's reasons.
@MainActor
@Suite("propose_subscription")
struct ProposeSubscriptionToolTests {
    private let changes = ChangeQueue()
    /// Quiet Timer sells nothing; Lumen Journal has the Lumen Plus group.
    private static let quiet = StoreApp(id: DebugFixtures.AppID.quiet, name: "Quiet Timer", bundleID: "dev.northpier.quiet", primaryLocale: "en-US")

    private func call(_ tool: some MCPTool, _ arguments: [String: JSONValue], client: String = "Claude Code") async throws -> MCPToolOutcome {
        let workspace = MCPTestFixtures.workspace(apps: MCPTestFixtures.apps + [Self.quiet], changes: changes)
        return try await tool.call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace, clientName: client))
    }

    private func arguments(_ overrides: [String: JSONValue] = [:]) -> [String: JSONValue] {
        var arguments: [String: JSONValue] = [
            "appId": "Quiet Timer",
            "group": "Quiet Plus",
            "groupDisplayName": "Quiet Plus",
            "referenceName": "Quiet Plus Monthly",
            "productId": "dev.northpier.quiet.plus.monthly",
            "duration": "ONE_MONTH",
            "displayName": "Quiet Plus",
            "description": "Every sound and timer",
            "price": .double(2.99),
            "evidence": ["Quiet/Store.swift:8 — buys dev.northpier.quiet.plus.monthly"],
        ]
        arguments.merge(overrides) { $1 }
        return arguments
    }

    @Test func aNewSubscriptionIsQueuedAsTheAssistants() async throws {
        let outcome = try await call(ProposeSubscriptionTool(), arguments())

        let id = "subscriptionSetup.\(Self.quiet.id).dev.northpier.quiet.plus.monthly"
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["changeId"] == .string(id))
        #expect(outcome.result["group"] == "Quiet Plus (new)")
        let change = try #require(changes.change(id: id))
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(change.newValue == "1 month · $2.99")
        #expect(change.creation?.fields.first { $0.id == "evidence" }?.newValue == "Quiet/Store.swift:8 — buys dev.northpier.quiet.plus.monthly")
        let price = try #require(change.requests.last)
        #expect(SubscriptionStartingPrices(price)?.customerPrice == Decimal(string: "2.99"))
        #expect(outcome.logLines == [.init(target: "Quiet Timer · Quiet Plus Monthly", outcome: .proposed)])
    }

    @Test func everythingAppStoreConnectWouldRefuseIsListed() async throws {
        let outcome = try await call(ProposeSubscriptionTool(), arguments([
            "groupDisplayName": "",
            "description": .string(String(repeating: "a", count: 46)),
        ]))
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reasons"]?.arrayValue?.count == 2)
        #expect(changes.changes.isEmpty)
    }

    @Test func anExistingGroupIsFoundByName() async throws {
        let outcome = try await call(ProposeSubscriptionTool(), arguments([
            "appId": "Lumen Journal",
            "group": "lumen plus",
            "groupDisplayName": .null,
            "productId": "lumen.plus.weekly",
            "duration": "ONE_WEEK",
        ]))
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["group"] == "Lumen Plus")
        let change = try #require(changes.changes.first)
        #expect(!change.requests.contains { $0.path == "/v2/subscriptionGroupLocalizations" })
    }

    @Test func aProductIDTheAppHasIsRefused() async throws {
        let outcome = try await call(ProposeSubscriptionTool(), arguments(["appId": "Lumen Journal", "group": "Lumen Plus", "productId": "lumen.plus.monthly"]))
        #expect(outcome.result["status"] == "refused")
        #expect(changes.changes.isEmpty)
    }

    @Test func thePersonsOwnNewSubscriptionIsLeftToThem() async throws {
        let builder = NewSubscriptionChangeBuilder(app: Self.quiet)
        var mine = NewSubscriptionChangeBuilderTests.monthly()
        mine.productID = "dev.northpier.quiet.plus.monthly"
        changes.upsert(builder.change(for: mine))

        let outcome = try await call(ProposeSubscriptionTool(), arguments())
        #expect(outcome.result["status"] == "refused")
        #expect(changes.changes.first?.source == .you)
    }

    @Test func proposingTheSameProductIDAgainReplacesIt() async throws {
        _ = try await call(ProposeSubscriptionTool(), arguments())
        _ = try await call(ProposeSubscriptionTool(), arguments(["price": "3.99"]))
        #expect(changes.changes.count == 1)
        #expect(changes.changes.first?.newValue == "1 month · $3.99")
    }

    @Test func anUnknownDurationIsAnArgumentError() async {
        await #expect(throws: MCPToolError.self) {
            _ = try await call(ProposeSubscriptionTool(), arguments(["duration": "ONE_DAY"]))
        }
    }

    @Test func getListsGroupsProductsAndWhatsQueued() async throws {
        _ = try await call(ProposeSubscriptionTool(), arguments())
        let quiet = try await call(GetSubscriptionsTool(), ["appId": "Quiet Timer"])
        #expect(quiet.result["groups"] == [])
        #expect(quiet.result["queued"]?.arrayValue?.first?["productId"] == "dev.northpier.quiet.plus.monthly")
        #expect(quiet.result["durations"]?.arrayValue?.count == SubscriptionPeriod.allCases.count)

        let lumen = try await call(GetSubscriptionsTool(), ["appId": "Lumen Journal"])
        let group = try #require(lumen.result["groups"]?.arrayValue?.first)
        #expect(group["referenceName"] == "Lumen Plus")
        #expect(group["subscriptions"]?.arrayValue?.compactMap { $0["productId"]?.stringValue } == ["lumen.plus.monthly", "lumen.plus.annual"])
        #expect(lumen.result["inAppPurchases"]?.arrayValue?.count == 1)
    }
}
#endif
