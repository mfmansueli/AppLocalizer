//
//  RerecordMomentTool.swift
//  AppLocalizer
//

import Foundation

/// `rerecord_moment`: a moment of the App Preview recorded again, because
/// the person asked at Pick. Without an upload it says what to record; with
/// one, the new take stands in for that moment and the rest of the
/// recording stays.
struct RerecordMomentTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "rerecord_moment",
        title: "Record an App Preview moment again",
        description: """
        Before the design step, records again a moment the person asked for at Pick (next_step says \
        record_again; list_recording_moments marks it recordAgain). Call it with moment_id alone to see what to \
        record and where; record only that screen the same way as the recording (xcrun simctl io <udid> \
        recordVideo --codec h264), upload it to the plan's upload URL, then call it again with the upload ID, \
        device and locale, and start_s/end_s when the screen has settled and ends. The new take stands in for \
        that moment of the device's recording; the rest stays.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "moment_id": MCPToolDefinition.string("The moment's id from list_recording_moments (its screen)."),
                "upload": MCPToolDefinition.string("The upload ID the upload URL returned for the new take."),
                "device": MCPToolDefinition.string("iphone or ipad."),
                "locale": MCPToolDefinition.string("The take's locale."),
                "start_s": ["type": "number", "description": "When the screen has settled in the take, in seconds."],
                "end_s": ["type": "number", "description": "When the moment ends in the take, in seconds."],
                "reason": MCPToolDefinition.string("Why this take works, in a short sentence."),
            ],
            required: ["appId", "moment_id"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        let screen = try session.screen(arguments.string("moment_id"))
        let run = session.run
        guard run.momentRetakes?.contains(screen.id) == true else {
            return .refused(String(localized: "Nobody asked to record “\(screen.name)” again."), target: session.target)
        }
        guard let id = try arguments.optionalString("upload"), !id.isEmpty else {
            let wanted: [JSONValue] = run.pickRecordingTargets.filter { run.isWaitingForRetake(screen.id, on: $0) }.map { target in
                var item = AutopilotNextStep.recordingJSON(target)
                if case var .object(fields) = item {
                    fields["was"] = run.moments(for: target).first { $0.screenID == screen.id }.map { moment in
                        .string("\(AutopilotRun.timeTitle(moment.start))–\(AutopilotRun.timeTitle(moment.end))")
                    } ?? .null
                    item = .object(fields)
                }
                return item
            }
            var result: [String: JSONValue] = [
                "moment": .string(screen.id),
                "screen": .string(screen.name),
                "steps": .string(screen.steps),
                "record": .array(wanted),
                "how": .string(Self.how),
            ]
            if run.motionRetakes?.contains(screen.id) == true {
                result["why"] = "AppLocalizer measured this moment: almost nothing moves in it, so it reads as a still image."
            }
            return MCPToolOutcome(result: .object(result), isError: false, logLines: [])
        }
        guard let upload = session.center.recordingUploads[id], upload.runID == run.id else {
            throw MCPToolError.notFound(String(localized: "No recording “\(id)” for this run. Upload the video to the plan’s upload URL first."))
        }
        let target = try ListRecordingMomentsTool.target(arguments, run: run)
        let place = "\(session.app.name) · \(screen.name) · \(target.locale) · \(target.displayType.title)"
        do {
            let retake = try AutopilotMomentRetake(
                screenID: screen.id, start: arguments.optionalDouble("start_s"), end: arguments.optionalDouble("end_s"),
                reason: arguments.optionalString("reason")
            )
            let take = try session.center.receiveRetake(appID: session.app.id, upload: upload, target: target, retake: retake)
            await session.center.measureRetake(take, file: upload.file.url, appID: session.app.id)
        } catch {
            return .refused(error.localizedDescription, target: place)
        }
        session.refresh()
        let left = session.run.retakeTargets.count
        let result: JSONValue = ["status": "received", "retakesLeft": .int(left)]
        return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: place, outcome: .proposed)])
    }

    static let how = """
    Launch the app on this screen with the plan's launch arguments for the locale, start recording, and for 6 to 8 s \
    do the thing a person does here so the screen changes: a slow real drag through a list, opening an item, typing \
    and letting the result arrive, a control animating. Something should move at least half that time, never more \
    than 2 s of nothing. Stop it with exactly killall -INT simctl, upload it with curl --data-binary and -H \
    'Content-Type: video/quicktime', and call rerecord_moment with the upload ID, device, locale, start_s and end_s, \
    the stretch where the action happens. Only the app may be on screen.
    """
}
