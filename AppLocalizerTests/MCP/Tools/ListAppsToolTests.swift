//
//  ListAppsToolTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("list_apps")
struct ListAppsToolTests {
    @Test func listsEveryAppWithItsPricingModeAndPendingCount() async throws {
        let changes = ChangeQueue()
        changes.upsert(PendingChange(
            id: "listing.de-DE.subtitle", appID: "6450000001", section: .storePage, group: "German", title: "Subtitle",
            oldValue: "", newValue: "Schreib es auf", source: .you, requests: []
        ))
        let pricingModes = PricingModeStore(defaults: nil)
        pricingModes.setMode(.keepPrices, for: "6450000003")
        let workspace = MCPTestFixtures.workspace(changes: changes, pricingModes: pricingModes)

        let outcome = try await ListAppsTool().call(MCPToolArguments(), in: MCPToolContext(workspace: workspace, clientName: "Claude Code"))

        let apps = try #require(outcome.result.arrayValue)
        #expect(apps.count == 4)
        #expect(apps[0] == [
            "appId": "6450000001", "name": "Lumen Journal", "bundleId": "com.northpier.lumen", "sku": "LUMEN-01",
            "primaryLocale": "en-US", "pricingMode": "showSuggestions", "pendingCount": 1,
        ])
        #expect(apps[1]["pricingMode"] == "keepPrices")
        #expect(apps[2]["sku"] == .null)
        #expect(outcome.logLines == [.init(target: "Northpier Studio · 4 apps", outcome: .read)])
    }

    @Test func isReadOnlyAndInTheStandardToolbox() {
        #expect(ListAppsTool().definition.isReadOnly)
        #expect(MCPToolbox.standard.toolNames.contains("list_apps"))
        #expect(MCPToolbox.standard.tool(named: "list_apps") != nil)
        #expect(MCPToolbox.standard.tool(named: "nope") == nil)
    }

    @Test func proposalsCarryTheAssistantAsTheirSource() {
        let context = MCPToolContext(workspace: MCPTestFixtures.workspace(), clientName: "Cursor")
        #expect(context.source == .assistant(client: "Cursor"))
    }
}
