//
//  MCPAutopilotFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// A workspace whose Lumen Journal screenshots (the sample document, in
/// memory) hold an Autopilot center of the test's own, and a way to call
/// an Autopilot tool on it as Claude Code.
@MainActor
struct MCPAutopilotFixtures {
    let center: AutopilotCenter
    let services: DebugScreenshotsServices
    let workspace: MCPWorkspace

    static let appID = DebugFixtures.AppID.lumen

    /// `run` installed in a fresh center, with `project` connected and
    /// `appSupport` keeping what the project scans reported.
    init(_ run: AutopilotRun? = nil, project: DesignProject? = nil, holdsStages: Bool = false, appSupport: AppSupportCenter? = nil) {
        center = AutopilotTestFixtures.center(holdsStages: holdsStages)
        if let project { center.setDesignProject(project, for: Self.appID) }
        if let run { center.install(run) }
        services = AutopilotTestFixtures.services(center)
        var storePage = DebugStorePageServices()
        storePage.screenshots = services
        storePage.appSupport = appSupport
        workspace = MCPTestFixtures.workspace(storePage: storePage)
    }

    /// The app's run now.
    var run: AutopilotRun? { center.run(for: Self.appID) }

    /// Calls `tool` on Lumen unless `arguments` names another app, with
    /// `simulators` as this Mac's.
    func call(
        _ tool: some MCPTool, _ arguments: [String: JSONValue] = [:], port: UInt16 = MCPEndpoint.defaultPort, simulators: MacSimulators? = nil
    ) async throws -> MCPToolOutcome {
        var arguments = arguments
        if arguments["appId"] == nil { arguments["appId"] = .string(Self.appID) }
        var context = MCPToolContext(workspace: workspace, clientName: AutopilotTestFixtures.client)
        context.port = port
        context.simulators = simulators
        return try await tool.call(MCPToolArguments(arguments), in: context)
    }

    /// A workspace whose screenshots have no Autopilot.
    static var withoutAutopilot: MCPWorkspace {
        var storePage = DebugStorePageServices()
        storePage.screenshots = DebugScreenshotsServices()
        return MCPTestFixtures.workspace(storePage: storePage)
    }
}
#endif
