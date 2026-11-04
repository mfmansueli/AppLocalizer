//
//  NextStepTool.swift
//  AppLocalizer
//

import Foundation

/// `next_step`: what the Autopilot run wants now — capture, wait for the
/// person, design, revise, write captions, or done.
struct NextStepTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "next_step",
        title: "Ask Autopilot what's next",
        description: """
        Says what the app's Screenshot Autopilot run wants from you now: capture (with the targets left and \
        problems to retry with their fix), wait (the person is picking or choosing; ask again after \
        retryAfterSeconds), design (get_design_brief then propose_direction), revise_direction (the person's \
        note), write_captions (missing or too long, then propose_captions with run), revise_app_preview (the \
        person's note on the App Preview, then revise_app_preview), or done. Call it after each step until it \
        says done.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
            ],
            required: ["appId"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        guard let center = context.workspace.services.screenshots.autopilot else {
            throw MCPToolError.unavailable(String(localized: "Screenshot Autopilot isn’t available here."))
        }
        if let wanted = try arguments.optionalString("run"), let run = center.run(for: app.id), wanted != run.id {
            throw MCPToolError.notFound(String(localized: "Run “\(wanted)” is over; \(app.name)’s current run is “\(run.id)”. Call get_capture_plan."))
        }
        // What stopped when AppLocalizer closed picks up first.
        if let run = center.run(for: app.id) {
            center.resumeInterruptedWork(app.id, context: MCPAutopilotSession.context(app: app, run: run, in: context))
        }
        let step = await center.nextStep(appID: app.id, client: context.clientName)
        var result = step.mcpJSON(run: center.run(for: app.id)).objectValue ?? [:]
        if case let .writeArtworkTexts(needs) = step,
           let profile = await AutopilotAppProfile.load(app: app, locales: needs.map(\.locale), in: context.workspace)
        {
            result["startFrom"] = profile.searchWordsJSON(for: needs.map(\.locale))
        }
        if let run = center.run(for: app.id) {
            result["run"] = .string(run.id)
            result["stage"] = .string(run.stage.rawValue)
        }
        return .read(.object(result), target: String(localized: "\(app.name) · Autopilot"))
    }
}
