//
//  ListRecordingMomentsTool.swift
//  AppLocalizer
//

import Foundation

/// `list_recording_moments`: the moments of a device's App Preview
/// recording in a language, with why each works, whether the person chose
/// it, and whether they asked for it again.
struct ListRecordingMomentsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "list_recording_moments",
        title: "List an App Preview recording's moments",
        description: """
        Lists the moments of the run's App Preview recording on a device in a language: id (the screen), screen, \
        start_s, end_s and reason, as marked in report_recording (or from when each screen appears), with chosen \
        (it goes in the App Preview: 6 s each plus a 6 s end card, within Apple's 15–30 s) and recordAgain (the \
        person asked for it again: record it and send it with rerecord_moment before the design step).
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "device": MCPToolDefinition.string("iphone or ipad; the first recording's device when left out."),
                "locale": MCPToolDefinition.string("The recording's locale; the primary language when left out."),
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let run = session.run
        guard !run.plan.recordingTargets.isEmpty else {
            return .refused(String(localized: "This run makes no App Preview."), target: session.target)
        }
        let target = try Self.target(arguments, run: run)
        guard run.previewRecording(for: target) != nil else {
            return .refused(String(localized: "No recording on \(target.displayType.title) (\(target.locale)) yet."), target: session.target)
        }
        let chosen = Set(run.chosenMomentIDs)
        let moments: [JSONValue] = run.moments(for: target).map { moment in
            [
                "id": .string(moment.screenID),
                "screen": .string(run.plan.screen(id: moment.screenID)?.name ?? moment.screenID),
                "start_s": .double((moment.start * 10).rounded() / 10),
                "end_s": .double((moment.end * 10).rounded() / 10),
                "reason": .string(moment.reason),
                "chosen": .bool(chosen.contains(moment.screenID)),
                "recordAgain": .bool(run.isWaitingForRetake(moment.screenID, on: target)),
            ]
        }
        let result: JSONValue = [
            "device": .string(target.displayType.mcpValue),
            "locale": .string(target.locale),
            "moments": .array(moments),
            "lengthSeconds": .int(run.pickedPreviewSeconds),
        ]
        return MCPToolOutcome(result: result, isError: false, logLines: [])
    }

    /// The device and language asked for, else the first recording's.
    static func target(_ arguments: MCPToolArguments, run: AutopilotRun) throws -> AutopilotRecordingTarget {
        let first = run.pickRecordingTargets.first ?? run.plan.recordingTargets.first
        let display = try arguments.optionalString("device").map { value in
            guard let display = ScreenshotDisplayType(mcpValue: value), run.plan.previewDisplays.contains(display) else {
                let devices = run.plan.previewDisplays.map(\.mcpValue).formatted(.list(type: .or))
                throw MCPToolError.invalidArgument(name: "device", expected: String(localized: "a device the App Preview is made for: \(devices)"))
            }
            return display
        } ?? first?.displayType ?? .iPhone
        let code = try arguments.optionalString("locale")
        let locale = try code.map { value in
            guard let locale = StoreLocaleCatalog.resolve(value).locale else {
                throw MCPToolError.invalidArgument(name: "locale", expected: String(localized: "one of the recorded locales: \(run.plan.recordedLocales.joined(separator: ", "))"))
            }
            return locale.code
        } ?? first?.locale ?? run.plan.primaryLocale
        return AutopilotRecordingTarget(displayType: display, locale: locale)
    }
}
