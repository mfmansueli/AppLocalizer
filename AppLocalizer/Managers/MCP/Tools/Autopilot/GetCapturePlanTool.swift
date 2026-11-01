//
//  GetCapturePlanTool.swift
//  AppLocalizer
//

import Foundation

/// `get_capture_plan`: the run the person started — screens and how to
/// reach each, devices, languages, simulator setup and the upload link.
/// Calling it picks the plan up: the run starts capturing.
struct GetCapturePlanTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_capture_plan",
        title: "Get the screenshot capture plan",
        description: """
        Reads the Screenshot Autopilot run the person started in AppLocalizer and picks it up: the screens \
        (id, name, the steps to reach each and the caption it goes with), the devices with their simulator \
        and pixel size, the locales with their launch arguments, the simulator setup commands, and the upload \
        URL for captures. Build the app, boot the simulators, run the setup, launch the app in each locale (with \
        its sample data in that language when simulatorSetup has sampleDataLanguage) and capture each screen \
        (XCUIScreen or xcrun simctl io booted screenshot). UI tests that capture take the locale's testArguments \
        (xcodebuild test … -testLanguage de -testRegion DE), and any switch they need from their scheme or test \
        plan, never from VAR=value in front of xcodebuild. Upload each PNG with curl to the upload URL and call \
        report_capture; act on any check it returns. Before capturing, go through preflight's checks in the project; \
        next_step gives the rehearsal first (every screen in the primary language and rehearsal.locale), so what \
        breaks in other languages breaks once. When chooseScreens is true, first decide from the project which \
        screens show the app best and send them with update_capture_plan replace: true, the strongest first: \
        the first three are the ones App Store search results show. Otherwise, if the \
        screens have no steps, write them from the project's UI tests, deep links or launch arguments and send \
        them with update_capture_plan first. Pass xcode and simulators so the person sees what you use.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID, if you have it."),
                "xcode": MCPToolDefinition.string("The Xcode version you build with, e.g. 26.1."),
                "simulators": ["type": "array", "items": ["type": "string"], "description": "The simulators you use, e.g. iPhone 17 Pro Max."],
            ],
            required: ["appId"]
        ),
        changesState: true
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        let environment = try Self.environment(arguments)
        session.center.pickUp(appID: session.app.id, client: context.clientName, environment: environment)
        session.refresh()
        return .read(session.run.mcpPlan(appName: session.app.name, bundleID: session.app.bundleID, port: context.port), target: session.target)
    }

    static func environment(_ arguments: MCPToolArguments) throws -> AutopilotEnvironment? {
        let xcode = try arguments.optionalString("xcode")
        let simulators = try arguments.optionalStrings("simulators") ?? []
        guard xcode != nil || !simulators.isEmpty else { return nil }
        return AutopilotEnvironment(xcode: xcode, simulators: simulators)
    }
}
