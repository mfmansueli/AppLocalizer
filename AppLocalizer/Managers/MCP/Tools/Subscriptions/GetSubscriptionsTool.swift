//
//  GetSubscriptionsTool.swift
//  AppLocalizer
//

import Foundation

/// `get_subscriptions`: an app's subscription groups with their
/// subscriptions, its in-app purchases, and the new subscriptions waiting in
/// Review & Push, so an assistant proposes only what's missing.
struct GetSubscriptionsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_subscriptions",
        title: "Get subscriptions",
        description: """
        Reads what an app sells in App Store Connect: each subscription group (id, referenceName) with its \
        subscriptions (id, productId, name, duration, state, price in the United States), its in-app purchases, \
        and the new subscriptions already waiting in Review & Push (queued). Use it before propose_subscription, \
        which creates the missing ones.
        """,
        inputSchema: MCPToolDefinition.schema(
            ["appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps.")],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let catalog = try await MCPPriceCatalog.load(app: arguments.string("appId"), in: context.workspace)
        let app = catalog.app
        let groups: [JSONValue] = catalog.catalog.groups.filter { !$0.isInAppPurchases }.map { group in
            [
                "id": .string(group.id),
                "referenceName": .string(group.name),
                "subscriptions": .array(group.products.map(Self.product)),
            ]
        }
        let purchases: [JSONValue] = catalog.catalog.inAppPurchases.map(Self.product)
        let queued: [JSONValue] = NewSubscriptionChangeBuilder.queued(in: context.workspace.changes, appID: app.id).map(Self.queued)
        let result: JSONValue = [
            "appId": .string(app.id),
            "app": .string(app.name),
            "bundleId": .string(app.bundleID),
            "primaryLocale": .string(app.primaryLocale ?? StoreLocale.englishUS.code),
            "groups": .array(groups),
            "inAppPurchases": .array(purchases),
            "queued": .array(queued),
            "durations": .array(SubscriptionPeriod.allCases.map { .string($0.rawValue) }),
        ]
        return .read(result, target: String(localized: "\(app.name) · subscriptions"))
    }

    private static func product(_ product: PricingProduct) -> JSONValue {
        var json: [String: JSONValue] = [
            "id": .string(product.id),
            "productId": .string(product.productID),
            "name": .string(product.name),
            "state": .string(product.reviewState),
        ]
        if let period = product.period { json["duration"] = .string(period.rawValue) }
        if let type = product.inAppPurchaseType { json["type"] = .string(type) }
        json["priceUSD"] = product.basePrice.map(MCPPriceValue.json) ?? .null
        return .object(json)
    }

    private static func queued(_ change: PendingChange) -> JSONValue {
        let fields = Dictionary((change.creation?.fields ?? []).map { ($0.id, $0.newValue) }, uniquingKeysWith: { first, _ in first })
        var json: [String: JSONValue] = [
            "changeId": .string(change.id),
            "referenceName": .string(change.title),
            "productId": .string(fields["productId"] ?? ""),
            "group": .string(fields["group"] ?? ""),
            "summary": .string(change.newValue),
            "by": .string(change.source.title),
        ]
        if let blocked = change.blockedReason { json["blockedReason"] = .string(blocked) }
        return .object(json)
    }
}
