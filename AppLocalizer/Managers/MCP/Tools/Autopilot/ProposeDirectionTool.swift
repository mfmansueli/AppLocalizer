//
//  ProposeDirectionTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_direction`: one design direction for the Autopilot run, as an
/// AppLocalizer template. Directions arrive one by one; the person
/// chooses.
struct ProposeDirectionTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_direction",
        title: "Propose a screenshot design direction",
        description: """
        Sends one design direction for the Autopilot run: a name ("Quiet Indigo"), a one-sentence rationale, \
        and the template — the JSON get_template returns (any subset of its fields) and/or ops on dotted paths — \
        laid on a base starter (above, band or panorama). When the run also makes header and search artwork or an \
        App Preview, they take this look; extrasTemplates can give them their own (get_design_brief's extras). \
        Refused, with the template check that failed, for unknown fields, values out of range or fonts that can't draw a language. Pass sourceLink to the \
        direction in the design project so the person can open it there. The result lists its language checks.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "name": MCPToolDefinition.string("The direction's name, e.g. Quiet Indigo."),
                "rationale": MCPToolDefinition.string("Why, in a sentence the person reads."),
                "base": MCPToolDefinition.string("above, band or panorama."),
                "template": ["type": "object", "description": "Template fields, as get_template returns them."],
                "ops": ["type": "array", "items": ["type": "object"], "description": "{op: \"replace\", path, value} changes."],
                "sourceLink": MCPToolDefinition.string("Where to refine it, e.g. the Claude Design project's link."),
                "extrasTemplates": MCPDirectionTemplate.extrasSchema,
            ],
            required: ["appId", "run", "name", "rationale"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        let base = try MCPDirectionTemplate.starter(arguments, app: session.app, slotCount: max(session.run.plan.screens.count, 1))
        let template: ScreenshotTemplate
        let extras: (artwork: ScreenshotTemplate?, preview: ScreenshotTemplate?)
        do {
            template = try MCPDirectionTemplate.template(arguments, base: base, fonts: session.context.services.fonts)
            extras = try MCPDirectionTemplate.extrasTemplates(arguments, over: template, fonts: session.context.services.fonts)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        let name = try arguments.string("name")
        let direction = try AutopilotDirection(
            id: "d-" + session.center.makeID().prefix(8), name: name, rationale: arguments.string("rationale"),
            source: session.run.designKind == .none ? .claudeDesign : session.run.designKind, client: context.clientName,
            template: template, artworkTemplate: extras.artwork, previewTemplate: extras.preview,
            link: arguments.optionalString("sourceLink"), receivedAt: session.center.now()
        )
        do {
            try await session.center.addDirection(direction, appID: session.app.id, context: session.context)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        session.refresh()
        let stored = session.run.directions.first { $0.id == direction.id }
        let result: JSONValue = [
            "status": "received",
            "direction": .string(direction.id),
            "received": .int(session.run.directions.count),
            "of": .int(AutopilotRun.directionCount),
            "checks": .array((stored?.checks ?? []).map { .string($0.title) }),
        ]
        return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: "\(session.target) · \(name)", outcome: .proposed)])
    }
}
