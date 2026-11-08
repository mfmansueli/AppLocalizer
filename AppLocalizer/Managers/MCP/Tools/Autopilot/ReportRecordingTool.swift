//
//  ReportRecordingTool.swift
//  AppLocalizer
//

import Foundation

/// `report_recording`: the App Preview's Simulator recording of the plan's
/// screens on a device in a language, sent to the upload link first, with
/// when each screen appears; or why it couldn't be made.
struct ReportRecordingTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "report_recording",
        title: "Report an App Preview recording",
        description: """
        Records the App Preview's Simulator recording for the Autopilot run: displayType (iphone or ipad), locale, \
        the upload ID the upload URL returned for the video (xcrun simctl io booted recordVideo --codec h264), and \
        marks: when each of the plan's screens appears, in seconds from the recording's start. AppLocalizer cuts \
        the App Preview from it (15–30 s), adds the captions and end card in the chosen direction, and checks it \
        against Apple's rules. When it can't be recorded, pass problem instead of upload: the run goes on without it.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "displayType": MCPToolDefinition.string("iphone or ipad."),
                "locale": MCPToolDefinition.string("The locale the app ran in, e.g. en-US."),
                "upload": MCPToolDefinition.string("The upload ID the upload URL returned for the video."),
                "marks": [
                    "type": "array",
                    "description": "When each screen appears: [{\"screen\": \"today\", \"seconds\": 1.5}, …], in the plan's order.",
                    "items": MCPToolDefinition.schema(
                        ["screen": MCPToolDefinition.string("The screen's id from the plan."), "seconds": ["type": "number"]],
                        required: ["screen", "seconds"]
                    ),
                ],
                "moments": [
                    "type": "array",
                    "description": """
                    The moments that work in an App Preview, one a screen, each with why: [{"screen": "week", "start_s": 9, \
                    "end_s": 15, "reason": "The week chart animates in", "use": true}, …]. use: false for one you advise \
                    against (a slow load, little to see). Marks can be left out when these are sent.
                    """,
                    "items": MCPToolDefinition.schema(
                        [
                            "screen": MCPToolDefinition.string("The screen's id from the plan."),
                            "start_s": ["type": "number"], "end_s": ["type": "number"],
                            "reason": MCPToolDefinition.string("Why it works, in a few words."),
                            "use": ["type": "boolean"],
                        ],
                        required: ["screen", "start_s", "end_s"]
                    ),
                ],
                "problem": MCPToolDefinition.string("Why it couldn't be recorded, instead of upload."),
            ],
            required: ["appId", "run", "displayType", "locale"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        let target = try recordingTarget(arguments, session: session)
        let place = "\(session.app.name) · App Preview · \(target.locale) · \(target.displayType.title)"
        if let problem = try arguments.optionalString("problem"), !problem.isEmpty, try (arguments.optionalString("upload") ?? "").isEmpty {
            do {
                try await session.center.skipRecording(appID: session.app.id, target: target, reason: problem, context: session.context)
            } catch {
                return .refused(error.localizedDescription, target: place)
            }
            session.refresh()
            return MCPToolOutcome(result: result(session, status: "left_out"), isError: false, logLines: [.init(target: place, outcome: .proposed)])
        }
        guard let id = try arguments.optionalString("upload"), !id.isEmpty else {
            throw MCPToolError.invalidArgument(name: "upload", expected: String(localized: "the upload ID from the plan’s upload URL, or problem"))
        }
        guard let upload = session.center.recordingUploads[id], upload.runID == session.run.id else {
            throw MCPToolError.notFound(String(localized: "No recording “\(id)” for this run. Upload the video to the plan’s upload URL first."))
        }
        do {
            _ = try await session.center.receiveRecording(
                appID: session.app.id, upload: upload, target: target, marks: Self.marks(arguments), moments: Self.moments(arguments),
                context: session.context
            )
        } catch {
            return .refused(error.localizedDescription, target: place)
        }
        session.refresh()
        return MCPToolOutcome(result: result(session, status: "received"), isError: false, logLines: [.init(target: place, outcome: .proposed)])
    }

    private func result(_ session: MCPAutopilotSession, status: String) -> JSONValue {
        var json: [String: JSONValue] = [
            "status": .string(status),
            "recordingsLeft": .int(session.run.remainingRecordings.count),
            "stage": .string(session.run.stage.rawValue),
        ]
        let still = session.run.momentsWaitingForMotion
        if !still.isEmpty {
            json["tooStill"] = .array(still.map { .string($0) })
            json["next"] = """
            Almost nothing moves in these moments, so the App Preview would read as a slideshow. next_step asks you to \
            record them again: make something happen on camera in each.
            """
        }
        return .object(json)
    }

    private func recordingTarget(_ arguments: MCPToolArguments, session: MCPAutopilotSession) throws -> AutopilotRecordingTarget {
        let displays = session.run.plan.previewDisplays
        let display = try arguments.optionalString("displayType").map { value in
            guard let display = ScreenshotDisplayType(mcpValue: value), displays.contains(display) else {
                let devices = displays.map(\.mcpValue).formatted(.list(type: .or))
                throw MCPToolError.invalidArgument(name: "displayType", expected: String(localized: "a device the App Preview is made for: \(devices)"))
            }
            return display
        } ?? .iPhone
        let code = try arguments.string("locale")
        guard let locale = StoreLocaleCatalog.resolve(code).locale else {
            throw MCPToolError.invalidArgument(name: "locale", expected: String(localized: "one of the locales to record: \(session.run.plan.recordedLocales.joined(separator: ", "))"))
        }
        return AutopilotRecordingTarget(displayType: display, locale: locale.code)
    }

    /// `[{screen, start_s, end_s, reason, use}]`.
    static func moments(_ arguments: MCPToolArguments) -> [AutopilotRecordingMoment] {
        guard case let .array(items)? = arguments.values["moments"] else { return [] }
        return items.compactMap { item in
            guard case let .object(fields) = item, let screen = fields["screen"]?.stringValue,
                  let start = fields["start_s"]?.doubleValue, let end = fields["end_s"]?.doubleValue else { return nil }
            return AutopilotRecordingMoment(
                screenID: screen, start: start, end: end, reason: fields["reason"]?.stringValue ?? "", suggested: fields["use"]?.boolValue
            )
        }
    }

    /// `[{screen, seconds}]`; a screen can be named by its ID, name or slot.
    static func marks(_ arguments: MCPToolArguments) -> [AutopilotRecordingMark] {
        guard case let .array(items)? = arguments.values["marks"] else { return [] }
        return items.compactMap { item in
            guard case let .object(fields) = item, let screen = fields["screen"]?.stringValue,
                  let seconds = fields["seconds"]?.doubleValue else { return nil }
            return AutopilotRecordingMark(screenID: screen, seconds: seconds)
        }
    }
}
