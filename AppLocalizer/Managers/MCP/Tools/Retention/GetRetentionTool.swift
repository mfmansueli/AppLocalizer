//
//  GetRetentionTool.swift
//  AppLocalizer
//

import Foundation

/// `get_retention`: an app's retention messages (what subscribers see on
/// Apple's Confirm Cancellation screen), its retention offers, the
/// subscriptions and languages, and Apple's limits, as Pricing → Retention
/// shows them.
struct GetRetentionTool: MCPTool {
    var store = RetentionDraftStore.shared

    let definition = MCPToolDefinition(
        name: "get_retention",
        title: "Get retention messages",
        description: """
        Reads an app's retention messages: what subscribers see on Apple's Confirm Cancellation screen after they \
        tap Cancel Subscription. Returns each message (id, referenceName, status draft/queued/inReview/live/rejected, \
        kind message/image/offer, the subscriptions that show it, header and body by locale with their lengths, \
        missing languages and what keeps it from being pushed), the retention offers by subscription, the \
        subscriptions (id, productId, name, duration, US price, the message it shows), the languages (sourceLocale \
        first) and Apple's limits: header ≤66 and body ≤144 characters, 10 messages an app, 10 offers a \
        subscription. Use it before propose_retention_message and propose_retention_offer.
        """,
        inputSchema: MCPToolDefinition.schema(
            ["appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps.")],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let retention = try await RetentionMCPContext.load(app: arguments.string("appId"), in: context.workspace, store: store)
        let result: JSONValue = [
            "appId": .string(retention.app.id),
            "app": .string(retention.app.name),
            "sourceLocale": .string(retention.content.sourceLocale.code),
            "languages": .array(retention.content.languages.map { .string($0.code) }),
            "limits": RetentionMCPJSON.limits(),
            "canAddMessage": .bool(retention.messages.count < RetentionLimits.messagesPerApp),
            "subscriptions": .array(retention.content.subscriptions.map { RetentionMCPJSON.subscription($0, in: retention) }),
            "messages": .array(retention.messages.map { RetentionMCPJSON.message($0, in: retention) }),
            "offers": .array(retention.offers.map { RetentionMCPJSON.offer($0, in: retention) }),
        ]
        return .read(result, target: retention.target)
    }
}
