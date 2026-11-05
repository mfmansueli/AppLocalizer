//
//  ProposeInAppTextsTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_in_app_texts`: an assistant's subscription group name or
/// product name and description, validated like an edit in Store Page →
/// In-App Texts and queued for review, one text or a batch at a time.
struct ProposeInAppTextsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_in_app_texts",
        title: "Propose In-App Texts",
        description: """
        Proposes an app's In-App Texts: the subscription group's display name (column group.name) and each \
        subscription's and in-app purchase's display name and description (<productId>.name, \
        <productId>.description), from get_in_app_texts. Send one with locale, column and text, or several with \
        proposals: [{locale, column, text}]. Each is checked like a manual edit: over the limit, empty, an unknown \
        column or locale, or a text the person already changed is refused with the reason (status "refused"). \
        Accepted proposals are queued for the person to review in AppLocalizer (status "queued"); a locale App \
        Store Connect doesn't have yet is created when they push, and needs a name (blockedReason says so). \
        Nothing reaches App Store Connect until they push.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "locale": MCPToolDefinition.string("An App Store Connect locale code, e.g. de-DE."),
                "column": MCPToolDefinition.string("The column id, e.g. group.name or lumen.monthly.description."),
                "text": MCPToolDefinition.string("The proposed text, within the column's limit."),
                "proposals": [
                    "type": "array",
                    "description": "Several proposals at once, instead of locale, column and text.",
                    "items": MCPToolDefinition.schema(
                        [
                            "locale": MCPToolDefinition.string("An App Store Connect locale code."),
                            "column": MCPToolDefinition.string("The column id."),
                            "text": MCPToolDefinition.string("The proposed text."),
                        ],
                        required: ["locale", "column", "text"]
                    ),
                ],
            ],
            required: ["appId"]
        ),
        proposalKind: .storeText
    )

    /// One cell's proposed text.
    private struct Proposal {
        var locale: String
        var column: String
        var text: String

        init(_ arguments: MCPToolArguments) throws {
            locale = try arguments.string("locale")
            column = try arguments.string("column")
            text = try arguments.string("text")
        }

        var key: String { "\(locale).\(column)" }
    }

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let batch = try arguments.optionalArray("proposals")
        let proposals = try batch.map { items in
            try items.map { item in
                guard let object = item.objectValue else {
                    throw MCPToolError.invalidArgument(name: "proposals", expected: String(localized: "a list of {locale, column, text} objects"))
                }
                return try Proposal(MCPToolArguments(object))
            }
        } ?? [Proposal(arguments)]

        var draft = try await MCPInAppTextsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let outcomes = proposals.map { draft.propose($0.text, column: $0.column, locale: $0.locale, by: context.clientName) }
        let committed = draft.commit(to: context.workspace.changes)

        var results: [JSONValue] = []
        var logLines: [MCPToolOutcome.LogLine] = []
        var queued = 0
        var refused = 0
        for (proposal, outcome) in zip(proposals, outcomes) {
            let code = StoreLocaleCatalog.locale(code: proposal.locale)?.code ?? proposal.locale
            var result: [String: JSONValue] = ["locale": .string(proposal.locale), "column": .string(proposal.column)]
            let target = draft.target(locale: proposal.locale, column: draft.column(id: proposal.column))
            switch outcome {
            // Proposed back to App Store Connect's text: nothing stays queued.
            case .queued where committed["\(code).\(proposal.column)"] == nil, .unchanged:
                result["status"] = "unchanged"
                result["note"] = "That's already the text in App Store Connect or in review; nothing new was queued."
                logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .read))
            case .queued:
                let change = committed["\(code).\(proposal.column)"]
                result["status"] = "queued"
                result["changeId"] = change.map { .string($0.id) } ?? .null
                if let blocked = change?.blockedReason { result["blockedReason"] = .string(blocked) }
                queued += 1
                logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .proposed))
            case let .refused(reason, count, limit):
                result["status"] = "refused"
                result["reason"] = .string(reason)
                if let count { result["count"] = .int(count) }
                if let limit { result["limit"] = ["max": .int(limit.maximum), "unit": "characters"] }
                refused += 1
                logLines.append(MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: reason))
            }
            results.append(.object(result))
        }
        guard batch != nil else { return MCPToolOutcome(result: results[0], isError: false, logLines: logLines) }
        let summary: JSONValue = ["results": .array(results), "queued": .int(queued), "refused": .int(refused)]
        return MCPToolOutcome(result: summary, isError: false, logLines: logLines)
    }
}
