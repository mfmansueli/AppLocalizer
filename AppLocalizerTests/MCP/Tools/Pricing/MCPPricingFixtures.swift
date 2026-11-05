//
//  MCPPricingFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The price tools against the DEBUG pricing services: Lumen Journal's
/// prototype prices, Tempo Metronome for Keep my prices.
@MainActor
enum MCPPricingFixtures {
    static let lumen = "6450000001"
    static let tempo = "6450000003"
    static let annual = DebugPricingCatalog.lumenAnnualID
    static let lifetime = DebugPricingCatalog.lumenLifetimeID
    static let client = "Claude Code"

    static func call(
        _ tool: some MCPTool,
        _ arguments: [String: JSONValue],
        changes: ChangeQueue = ChangeQueue(),
        modes: [StoreApp.ID: PricingMode] = [tempo: .keepPrices],
        commission: Commission = .smallBusiness,
        pricing: (any PricingServices)? = nil
    ) async throws -> MCPToolOutcome {
        let workspace = MCPTestFixtures.workspace(
            changes: changes,
            pricingModes: PricingModeStore(defaults: nil, modes: modes),
            pricing: pricing,
            commission: commission
        )
        return try await tool.call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace, clientName: client))
    }

    /// The change the person's own edit of one Annual price queues.
    static func personsChange(_ territoryID: String, to price: String, source: ChangeSource = .you) throws -> PendingChange {
        let product = try #require(DebugPricingCatalog.catalog(for: lumen).product(id: annual))
        let sheet = DebugPriceSheets.sheet(for: product, commission: .smallBusiness, canReadSales: true)
        let territory = try #require(TerritoryCatalog.standard.territory(alpha3: territoryID))
        let current = try #require(sheet.prices[territoryID]?.current)
        let point = try #require(sheet.ladders[territoryID]?.point(at: PricingFixtures.money(price)))
        return PriceChangeFactory(appID: lumen, product: product).change(for: territory, from: current, to: point, source: source)
    }

    static func changeID(_ territoryID: String) -> String {
        PriceChangeFactory.changeID(productID: annual, territoryID: territoryID)
    }
}
#endif
