//
//  ProposeScreensTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_screens`: the assistant's answer to Suggest Screens. Shown in
/// the plan with why and how; the person adds the ones they want.
struct ProposeScreensTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_screens",
        title: "Suggest screens for the plan",
        description: """
        Answers next_step's suggest_screens: screens the app's screenshot set is missing, each with its name, why \
        (reason), what shows it (evidence: a file, target or commit), how to reach it from launch (steps, like the \
        plan's) and a caption in the primary language. AppLocalizer shows them under the plan's screens; the person \
        adds the ones they want with Add to Plan. Nothing is added on its own.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from next_step."),
                "screens": [
                    "type": "array",
                    "description": "Best first, at most next_step's room.",
                    "items": MCPToolDefinition.schema(
                        [
                            "name": MCPToolDefinition.string("The screen's name, e.g. Insights."),
                            "reason": MCPToolDefinition.string("Why it shows the app well, in a sentence."),
                            "evidence": MCPToolDefinition.string("The file, target or commit that shows it."),
                            "steps": MCPToolDefinition.string("How to reach it from launch, e.g. tab “Insights” → wait for the mood chart."),
                            "caption": MCPToolDefinition.string("The primary language's headline, 3–6 words."),
                        ],
                        required: ["name", "reason", "steps"]
                    ),
                ],
            ],
            required: ["appId", "screens"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context, atPlan: true)
        let room = AutopilotCenter.maximumScreens - session.run.plan.screens.count
        let items = try arguments.array("screens").prefix(max(room, 0)).enumerated().map { index, value in
            let item = MCPToolArguments(value.objectValue ?? [:])
            return try AutopilotScreenSuggestion(
                id: "\(session.center.makeID())-\(index)", name: item.string("name"), reason: item.string("reason"),
                evidence: item.optionalString("evidence"), steps: item.string("steps"), caption: item.optionalString("caption") ?? ""
            )
        }
        do {
            let suggestions = try session.center.receiveScreenSuggestions(items, client: context.clientName, appID: session.app.id)
            let result: JSONValue = [
                "status": "shown",
                "count": .int(suggestions.items.count),
                "say": "The person sees them in the plan and adds the ones they want. Nothing else to do now.",
            ]
            return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: session.target, outcome: .proposed)])
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
    }
}
