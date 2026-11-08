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
        URL for captures. A device with simulatorId is captured on that simulator (boot it and pass its id in \
        place of booted), the one Plan showed the person. Build the app, boot the simulators, run the setup, launch the app in each locale (with \
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
        them with update_capture_plan first. When appLook's status isn't known, read the app's look and design \
        language in the project first and send it with report_app_support's look, as appLook says: every design in \
        the run starts from it. Pass xcode and simulators so the person sees what you use.
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
        var plan = session.run.mcpPlan(appName: session.app.name, bundleID: session.app.bundleID, port: context.port)
        Self.addAppLook(&plan, appID: session.app.id, in: context)
        Self.addSimulatorIDs(&plan, inventory: context.simulators?.inventory)
        return .read(plan, target: session.target)
    }

    /// Each device's `simulatorId` and `runtime`: the simulator Plan's This
    /// Mac checked, so captures don't come from another of the same name
    /// (Bruma's iPad came from iOS 26.5 while Plan showed 27.2). Left out
    /// before This Mac is checked, and for Mac.
    static func addSimulatorIDs(_ plan: inout JSONValue, inventory: SimulatorInventory?) {
        guard let inventory, case var .object(json) = plan, case let .array(devices) = json["devices"] else { return }
        json["devices"] = .array(devices.map { device in
            guard case var .object(item) = device,
                  let display = item["displayType"]?.stringValue.flatMap(ScreenshotDisplayType.init(mcpValue:)),
                  let simulator = inventory.simulator(for: display) else { return device }
            item["simulatorId"] = .string(simulator.udid)
            if let runtime = inventory.runtime(of: simulator) { item["runtime"] = .string(runtime.name) }
            return .object(item)
        })
        plan = .object(json)
    }

    /// `appLook`: what the designers will know of the app, or how to read
    /// it from the project first. Left out when this AppLocalizer keeps no
    /// project reports.
    static func addAppLook(_ plan: inout JSONValue, appID: StoreApp.ID, in context: MCPToolContext) {
        guard let center = context.workspace.services.storePage.appSupport, case var .object(json) = plan else { return }
        json["appLook"] = AppLookProfile.mcpCapturePlanNote(center.profile(for: appID)?.look)
        if let knowledge = center.knowledge(for: appID), !knowledge.isEmpty { json["appKnowledge"] = knowledge.mcpJSON }
        plan = .object(json)
    }

    static func environment(_ arguments: MCPToolArguments) throws -> AutopilotEnvironment? {
        let xcode = try arguments.optionalString("xcode")
        let simulators = try arguments.optionalStrings("simulators") ?? []
        guard xcode != nil || !simulators.isEmpty else { return nil }
        return AutopilotEnvironment(xcode: xcode, simulators: simulators)
    }
}
