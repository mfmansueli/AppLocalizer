//
//  ListProposalsTool.swift
//  AppLocalizer
//

import Foundation

/// `list_proposals`: the app's screenshot proposals and where each stands.
struct ListProposalsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "list_proposals",
        title: "List screenshot proposals",
        description: """
        Lists the screenshot proposals sent for an app, oldest first: proposalId, kind (template or captions), \
        the template version a template proposal is based on, and status: pending, stale (based on an older \
        template version; the person rebases or discards it), accepted, partial or rejected.
        """,
        inputSchema: MCPToolDefinition.schema(
            ["appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps.")],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let current = draft.document.history?.currentNumber
        let proposals = draft.document.proposals.map { proposal -> JSONValue in
            let isStale = current.map { proposal.isStale(currentVersion: $0) } ?? false
            var entry: [String: JSONValue] = [
                "proposalId": .string(proposal.id),
                "kind": .string(proposal.kind.rawValue),
                "title": .string(proposal.title),
                "client": .string(proposal.client),
                "status": .string(isStale ? "stale" : proposal.status.toolValue),
                "receivedAt": .string(proposal.receivedAt.formatted(.iso8601)),
            ]
            if let basedOn = proposal.basedOnVersion { entry["basedOn"] = .int(basedOn) }
            if proposal.kind == .captions { entry["captions"] = .int(proposal.captions.count) }
            return .object(entry)
        }
        return .read(["appId": .string(draft.app.id), "proposals": .array(proposals)], target: draft.target)
    }
}
