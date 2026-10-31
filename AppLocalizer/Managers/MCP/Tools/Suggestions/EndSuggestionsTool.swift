//
//  EndSuggestionsTool.swift
//  AppLocalizer
//

import Foundation

/// `end_suggestions`: the assistant sent everything it will for a Suggest
/// Everything run. What arrived stays for the person to review; planned
/// fields that never came stop showing as coming.
struct EndSuggestionsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "end_suggestions",
        title: "End suggesting everything",
        description: """
        Ends a Suggest Everything run once you've sent every suggestion you will. What arrived stays in \
        AppLocalizer for the person to review. Returns the run's status (finished, or stopped when the person \
        stopped receiving) and how many of its fields arrived.
        """,
        inputSchema: MCPToolDefinition.schema(
            ["run": MCPToolDefinition.string("The run begin_suggestions returned.")],
            required: ["run"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        guard let store = context.workspace.suggestions else {
            throw MCPToolError.unavailable(String(localized: "Suggestions aren’t available right now. Ask the person to open AppLocalizer."))
        }
        let id = try arguments.string("run")
        if store.isStopped(id) {
            return .read(["run": .string(id), "status": "stopped"], target: id)
        }
        guard let run = store.run, run.id == id, run.phase != .waiting else {
            throw MCPToolError.notFound(String(localized: "There’s no run “\(id)” going on. Start one with begin_suggestions."))
        }
        store.endRun(id: id)
        let result: JSONValue = [
            "run": .string(id),
            "status": "finished",
            "received": .int(run.received),
            "total": .int(run.total),
        ]
        return .read(result, target: id)
    }
}
