//
//  ReviseDirectionTool.swift
//  AppLocalizer
//

import Foundation

/// `revise_direction`: a direction changed after the person's "Ask for
/// changes" note.
struct ReviseDirectionTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "revise_direction",
        title: "Revise a screenshot design direction",
        description: """
        Sends a revised direction after the person asked for changes (next_step gives the note): the \
        direction's id (or name) and its new template fields and/or ops, laid on the direction as it is. \
        Optionally a new rationale and sourceLink. The run goes back to the person to choose.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "direction": MCPToolDefinition.string("The direction's id or name."),
                "template": ["type": "object", "description": "Template fields, as get_template returns them."],
                "ops": ["type": "array", "items": ["type": "object"], "description": "{op: \"replace\", path, value} changes."],
                "rationale": MCPToolDefinition.string("What changed, in a sentence."),
                "sourceLink": MCPToolDefinition.string("Where to refine it."),
            ],
            required: ["appId", "run", "direction"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let wanted = try arguments.string("direction")
        guard let direction = session.run.directions.first(where: { $0.id == wanted || $0.name.localizedCaseInsensitiveCompare(wanted) == .orderedSame }) else {
            let ids = session.run.directions.map { "\($0.id) (\($0.name))" }.formatted(.list(type: .or))
            return .refused(String(localized: "No direction “\(wanted)” in this run; it has \(ids)."), target: session.target)
        }
        do {
            let template = try MCPDirectionTemplate.template(arguments, base: direction.template, fonts: session.context.services.fonts)
            try await session.center.reviseDirection(
                direction.id, template: template, rationale: arguments.optionalString("rationale"),
                link: arguments.optionalString("sourceLink"), appID: session.app.id, context: session.context
            )
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        let result: JSONValue = ["status": "revised", "direction": .string(direction.id)]
        return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: "\(session.target) · \(direction.name)", outcome: .proposed)])
    }
}
