//
//  StartDisplayRecordingTool.swift
//  AppLocalizer
//

import Foundation

/// `start_display_recording`: right before a UI test on iPhone Duo,
/// AppLocalizer opens the Duo if it's closed and records its inner display
/// (`DisplayRecorder`), since the test's own screenshot there is the cover
/// display and the test closes the app right after it.
/// `finish_display_recording` gives back the frames.
struct StartDisplayRecordingTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "start_display_recording",
        title: "Record iPhone Duo’s inner display",
        description: """
        Call this right before running a UI test on iPhone Duo. A UI test's screenshot there (XCUIScreen.main) is the \
        cover display, and the test closes the app right after it, too soon to screenshot the inner display yourself. \
        AppLocalizer opens the Duo if it's closed, then records its inner display at full size. Run the test on the \
        simulator it names, with -resultBundlePath (one screen or several, in any language), then call \
        finish_display_recording with that path: each screenshot the test attached comes back as the inner display at \
        that moment, with an upload ID for report_capture. The project needs no change for it.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "displayType": MCPToolDefinition.string("iphone_duo, the only device that needs it."),
            ],
            required: ["appId", "run"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let value = try arguments.optionalString("displayType") ?? ScreenshotDisplayType.iPhoneDuo.mcpValue
        guard ScreenshotDisplayType(mcpValue: value) == .iPhoneDuo else {
            throw MCPToolError.invalidArgument(
                name: "displayType", expected: String(localized: "iphone_duo: on the other devices the UI test’s own screenshot is the whole screen")
            )
        }
        guard session.run.plan.displayTypes.contains(.iPhoneDuo) else {
            throw MCPToolError.notFound(String(localized: "The plan doesn’t capture iPhone Duo."))
        }
        guard let simulators = context.simulators, simulators.hasHelper else {
            return .refused(String(localized: """
            AppLocalizer’s helper isn’t installed, so it can’t record iPhone Duo. Report it with report_capture_problem \
            (displayType iphone_duo, affectsDevice true).
            """), target: session.target)
        }
        let center = session.center
        let appID = session.app.id
        let state = await simulators.duo.makeOpen(within: .seconds(120)) { event in
            center.update(appID) { $0.appendLog(event.logText, kind: .event, at: center.now()) }
        }
        guard state == .open, let inner = simulators.duo.innerDisplay else {
            return .refused(String(localized: """
            iPhone Duo isn’t open, and AppLocalizer can’t open it by itself now: \(state.summary) Report it with \
            report_capture_problem (displayType iphone_duo, affectsDevice true): its card shows the person what \
            AppLocalizer sees, and the run tries iPhone Duo again by itself once it’s open.
            """), target: session.target, details: ["duo": .string(state.summary)])
        }
        do {
            try await simulators.recorder.start(udid: inner.udid, display: inner.display)
        } catch {
            return .refused(error.localizedDescription + " " + String(localized: """
            Report it with report_capture_problem (displayType iphone_duo, affectsDevice true).
            """), target: session.target)
        }
        let next = String(localized: """
        Run the UI test now on this simulator (-destination 'id=\(inner.udid)') with -resultBundlePath and an absolute path, \
        then call finish_display_recording with that path. Don’t screenshot iPhone Duo yourself meanwhile.
        """)
        return MCPToolOutcome(
            result: ["status": "recording", "simulator": .string(inner.udid), "next": .string(next)],
            isError: false, logLines: [.init(target: session.target, outcome: .read)]
        )
    }
}
