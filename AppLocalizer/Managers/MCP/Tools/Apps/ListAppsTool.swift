//
//  ListAppsTool.swift
//  AppLocalizer
//

import Foundation

/// `list_apps`: every app in the account with its IDs, pricing mode and how
/// many changes wait in review. Assistants start here to find an `appId`.
struct ListAppsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "list_apps",
        title: "List apps",
        description: """
        Lists every app in the App Store Connect account open in AppLocalizer: appId (the Apple ID other tools \
        take), name, bundleId, sku, primaryLocale, pricingMode (showSuggestions, applyRecommended or keepPrices; \
        price proposals are refused for keepPrices) and pendingCount (changes waiting in review).
        """,
        inputSchema: MCPToolDefinition.schema()
    )

    func call(_: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let workspace = context.workspace
        let apps = try await workspace.apps()
        let entries: [JSONValue] = apps.map { app in
            [
                "appId": .string(app.id),
                "name": .string(app.name),
                "bundleId": .string(app.bundleID),
                "sku": app.sku.map(JSONValue.string) ?? .null,
                "primaryLocale": app.primaryLocale.map(JSONValue.string) ?? .null,
                "pricingMode": .string(workspace.pricingModes.mode(for: app.id).rawValue),
                "pendingCount": .int(workspace.changes.count(for: app.id)),
            ]
        }
        let target = String(localized: "\(workspace.teamName) · \(apps.count) apps")
        return .read(.array(entries), target: target)
    }
}
