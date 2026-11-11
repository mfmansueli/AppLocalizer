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
        retryAfterSeconds), design (get_design_brief then propose_direction; with prompts, the header and search \
        concepts with propose_artwork_concept, and with Motion loop each concept's motion prompt, its animated pages \
        with revise_artwork_concept), revise_direction or revise (the person's note; revise_artwork_concept \
        for concepts), animate_header and revise_loop (the chosen header's loop, with revise_artwork_concept), \
        write_captions (missing or too long, then propose_captions with run), revise_app_preview (the \
        person's note on the App Preview, then revise_app_preview), answer_app_questions (what AppLocalizer wants to \
        know about the app, then answer_app_questions), choose_screens (the plan has none yet, then \
        update_capture_plan), or done. Call it after each step until it says done.
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

    /// Before a run's first capture or recording, once a run and only for
    /// what isn't known or has grown old: the assistant is reading the
    /// project anyway, and the next step comes right after. Music picked in
    /// an earlier run applies now.
    private static func askAboutApp(
        before step: AutopilotNextStep, app: StoreApp, center: AutopilotCenter, in context: MCPToolContext
    ) -> JSONValue? {
        guard let support = context.workspace.services.storePage.appSupport, let run = center.run(for: app.id) else { return nil }
        let knowledge = support.knowledge(for: app.id) ?? AppKnowledge()
        if let music = knowledge.music { center.suggestPreviewMusic(music, appID: app.id) }
        switch step {
        case .capture, .record, .chooseScreens: break
        default: return nil
        }
        let due = knowledge.due(now: .now)
        guard run.appQuestionsAskedAt == nil, !due.isEmpty else { return nil }
        center.markAppQuestionsAsked(appID: app.id)
        var json = AppKnowledge.askStepJSON(due, asksMusic: run.plan.alsoMakes.makesAppPreview).objectValue ?? [:]
        json["run"] = .string(run.id)
        json["stage"] = .string(run.stage.rawValue)
        return .object(json)
    }

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
        // Folded before its closed screens are given, whatever it was left as.
        let duo = await NextStepDuoPose.prepare(app: app, center: center, in: context)
        let step = await center.nextStep(appID: app.id, client: context.clientName)
        if let questions = Self.askAboutApp(before: step, app: app, center: center, in: context) {
            return .read(questions, target: String(localized: "\(app.name) · Autopilot"))
        }
        var result = step.mcpJSON(run: center.run(for: app.id)).objectValue ?? [:]
        MacCapacity.addGuidance(to: &result, capacity: context.macCapacity())
        if let duo, case .capture = step { result["iPhoneDuo"] = .string(duo) }
        if case let .writeArtworkTexts(needs) = step,
           let profile = await AutopilotAppProfile.load(app: app, locales: needs.map(\.locale), in: context.workspace)
        {
            result["startFrom"] = profile.searchWordsJSON(for: needs.map(\.locale))
        }
        if let run = center.run(for: app.id) {
            result["run"] = .string(run.id)
            result["stage"] = .string(run.stage.rawValue)
            let session = MCPAutopilotSession(
                app: app, center: center, context: MCPAutopilotSession.context(app: app, run: run, in: context), run: run
            )
            let prompts = await Self.prompts(for: step, session: session, context: context)
            if !prompts.isEmpty {
                result["prompts"] = .array(prompts.map(\.mcpJSON))
                result["promptsHow"] = """
                Follow each prompt as written: its text is the whole instruction (version and id are for the log). \
                get_design_brief attaches the picks and the icon they refer to.
                """
            }
        }
        return .read(.object(result), target: String(localized: "\(app.name) · Autopilot"))
    }
}
