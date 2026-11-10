//
//  ProposeScreensTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_screens`: screens for the plan, each with why and how. As the
/// answer to Suggest Screens they show in the open plan; at any other time
/// (Review & Push, or no run at all) they're kept for the app's next plan.
/// Either way the person adds the ones they want.
struct ProposeScreensTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_screens",
        title: "Suggest screens for the plan",
        description: """
        Suggests screens for the app's screenshot plan, each with its name, why (reason), what shows it (evidence: \
        a file, target or commit), how to reach it from launch (steps, like the plan's) and a caption in the primary \
        language (none on Apple Watch). As the answer to next_step's suggest_screens (pass its run), they show under \
        that device's screens in the open plan (status shown). At any other time, with or without a run (at Review & \
        Push, say, when the app gained a screen), they're queued for the app's next plan (status queued, with a \
        proposalId): pass device watch for the Apple Watch app's own screens; otherwise they're the set's, for \
        iPhone and iPad. Either way the person adds the ones they want with Add to Plan; nothing is added on its \
        own. A screen the plan already has is refused: send its new steps with update_capture_plan.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from next_step, when answering suggest_screens."),
                "device": MCPToolDefinition.string("""
                Outside suggest_screens: watch for the Apple Watch app's own screens; leave out for the set's (iPhone and \
                iPad). suggest_screens names its own device.
                """),
                "screens": [
                    "type": "array",
                    "description": "Best first, at most next_step's room (10 outside suggest_screens).",
                    "items": MCPToolDefinition.schema(
                        [
                            "name": MCPToolDefinition.string("The screen's name, e.g. Insights."),
                            "reason": MCPToolDefinition.string("Why it shows the app well, in a sentence."),
                            "evidence": MCPToolDefinition.string("The file, target or commit that shows it."),
                            "steps": MCPToolDefinition.string("How to reach it from launch, e.g. tab “Insights” → wait for the mood chart."),
                            "caption": MCPToolDefinition.string("The primary language's headline, 3–6 words. Left out on Apple Watch."),
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
        let (app, center) = try await MCPAutopilotSession.center(arguments, in: context)
        if let run = center.run(for: app.id), run.stage == .plan, run.screenRequest != nil {
            return try await answer(arguments, in: context)
        }
        return try queue(arguments, app: app, center: center, client: context.clientName)
    }

    /// The answer to Suggest Screens: shown in the open plan.
    private func answer(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context, atPlan: true)
        let room = session.run.plan.screenRoom(on: session.run.screenRequest?.device ?? .iPhone)
        let items = try arguments.array("screens").prefix(max(room, 0)).enumerated().map { index, value in
            try Self.suggestion(value, id: "\(session.center.makeID())-\(index)")
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

    /// Outside Suggest Screens: kept for the app's next plan, on the set or
    /// Apple Watch. Screens the plan already has are turned away.
    private func queue(_ arguments: MCPToolArguments, app: StoreApp, center: AutopilotCenter, client: String) throws -> MCPToolOutcome {
        let target = MCPAutopilotSession.target(app)
        let display = try Self.device(arguments)
        if display == .visionPro {
            return .refused(String(localized: "Apple Vision Pro’s windows show the iPhone screens: suggest those instead."), target: target)
        }
        let planned = center.run(for: app.id)?.plan.screens(on: display) ?? []
        var refused: [JSONValue] = []
        var items: [AutopilotScreenSuggestion] = []
        for (index, value) in try arguments.array("screens").prefix(AutopilotCenter.maximumScreens).enumerated() {
            let item = try Self.suggestion(value, id: "\(center.makeID())-\(index)")
            if planned.contains(where: { item.isNamed($0.name) }) {
                let reason = String(localized: "The plan already has “\(item.name)”: send its new steps with update_capture_plan.")
                refused.append(["name": .string(item.name), "reason": .string(reason)])
            } else {
                items.append(item)
            }
        }
        guard !items.isEmpty else {
            let reason = String(localized: "Nothing new to suggest: every screen sent is in the plan already.")
            return .refused(reason, target: target, details: ["refused": .array(refused)])
        }
        let queued: AutopilotScreenSuggestions
        do {
            queued = try center.queueScreenSuggestions(items, on: display, client: client, appID: app.id)
        } catch {
            return .refused(error.localizedDescription, target: target)
        }
        var result: [String: JSONValue] = [
            "status": refused.isEmpty ? "queued" : "partial",
            "proposalId": .string(queued.id ?? ""),
            "device": .string(display == .watch ? "watch" : "set"),
            "count": .int(queued.items.count),
            "say": """
            AppLocalizer keeps them for the app's next plan: when it opens, the person adds the ones they want with Add \
            to Plan. Nothing is added on its own.
            """,
        ]
        if !refused.isEmpty { result["refused"] = .array(refused) }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }

    /// One screen as sent.
    private static func suggestion(_ value: JSONValue, id: String) throws -> AutopilotScreenSuggestion {
        let item = MCPToolArguments(value.objectValue ?? [:])
        return try AutopilotScreenSuggestion(
            id: id, name: item.string("name"), reason: item.string("reason"),
            evidence: item.optionalString("evidence"), steps: item.string("steps"), caption: item.optionalString("caption") ?? ""
        )
    }

    /// Apple Watch, Apple Vision Pro, or the set (iPhone for any other
    /// device).
    private static func device(_ arguments: MCPToolArguments) throws -> ScreenshotDisplayType {
        guard let value = try arguments.optionalString("device"), value.lowercased() != "set" else { return .iPhone }
        guard let display = ScreenshotDisplayType(mcpValue: value) else {
            throw MCPToolError.invalidArgument(name: "device", expected: String(localized: "watch, or nothing for the set’s screens"))
        }
        return display.hasOwnScreens ? display : .iPhone
    }
}
