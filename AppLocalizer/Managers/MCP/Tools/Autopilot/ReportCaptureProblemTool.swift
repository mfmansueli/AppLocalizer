//
//  ReportCaptureProblemTool.swift
//  AppLocalizer
//

import Foundation

/// `report_capture_problem`: a screen that couldn't be reached, and the
/// fix the assistant proposes. The person decides; the others go on.
struct ReportCaptureProblemTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "report_capture_problem",
        title: "Report a capture problem",
        description: """
        Tells the person a screen couldn't be captured on a device in a locale: what happened ("The photo \
        picker asked for access and covered the entry") and the fix you propose, as a command or step (e.g. \
        xcrun simctl privacy booted grant photos <bundle ID>). When a command was refused (not allowed in this \
        session), pass it as refusedCommand and don't try it in another form; proposedFix then says what to \
        change in the project so it isn't needed (e.g. a scheme that sets the environment variable). When the fix \
        is a change to the project (a test, a scheme, sample data) rather than a command, pass changesProject: \
        true, with the file and line in proposedFix, and report it once: AppLocalizer holds the same screen on \
        that device in the other languages, and the person answers for all of them. When the fix is a step for the \
        person that isn't a command (install something, sign in), pass changesProject: false. When no screen on \
        the device can be captured in any language (this Mac has no simulator for it, e.g. iPhone Duo without an \
        iOS 27.1 runtime), report it once with affectsDevice: true and go on with the other devices; don't download \
        simulator runtimes yourself: AppLocalizer offers the person to install them. Don't stop: capture the \
        other screens. The person retries with the fix (next_step then lists it under retryWithFix), reuses the \
        primary language's capture, keeps the capture already sent, or uploads one by hand.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "screen": MCPToolDefinition.string("The screen's id from the plan."),
                "displayType": MCPToolDefinition.string("The plan's device: iphone, iphone_duo, ipad, watch or vision."),
                "locale": MCPToolDefinition.string("The locale, e.g. de-DE."),
                "what": MCPToolDefinition.string("What happened, in a sentence."),
                "proposedFix": MCPToolDefinition.string("A command or step that would fix it."),
                "refusedCommand": MCPToolDefinition.string("The command that wasn't allowed, when that's what stopped you."),
                "changesProject": [
                    "type": "boolean",
                    "description": "True when the fix is a change to the project (code, a test, a scheme, sample data), false when it isn't.",
                ],
                "affectsDevice": [
                    "type": "boolean",
                    "description": "True when no screen on this device can be captured in any language, e.g. this Mac has no simulator for it.",
                ],
            ],
            required: ["appId", "run", "screen", "displayType", "locale", "what"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let target = try session.captureTarget(arguments)
        do {
            let problem = try session.center.reportProblem(
                appID: session.app.id, target: target, what: arguments.string("what"), proposedFix: arguments.optionalString("proposedFix"),
                refusedCommand: arguments.optionalString("refusedCommand"), changesProject: arguments.optionalBool("changesProject"),
                affectsDevice: arguments.optionalBool("affectsDevice")
            )
            let result: JSONValue = [
                "status": "reported",
                "problem": .string(problem.id),
                "say": .string(Self.say(problem)),
            ]
            return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: session.target(target), outcome: .proposed)])
        } catch {
            return .refused(error.localizedDescription, target: session.target(target))
        }
    }

    /// What waits now, and what to go on with.
    static func say(_ problem: AutopilotProblem) -> String {
        if problem.isDeviceWide {
            return "The person decides in AppLocalizer. Every screen on this device waits, in every language; go on with the other devices."
        }
        if problem.needsProjectChange {
            return "The person decides in AppLocalizer. This screen waits on this device in the other languages; go on with the other screens."
        }
        return "The person decides in AppLocalizer. Go on with the other screens; next_step lists the retries."
    }
}
