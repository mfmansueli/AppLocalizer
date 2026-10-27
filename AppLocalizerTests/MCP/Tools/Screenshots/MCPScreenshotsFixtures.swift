//
//  MCPScreenshotsFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// Workspaces whose Lumen Journal screenshots are a sample document held
/// in memory, and a way to call a screenshot tool on them.
@MainActor
enum MCPScreenshotsFixtures {
    static let appID = DebugFixtures.AppID.lumen

    /// A workspace on `document`, and the services that keep it (with a
    /// document center of their own).
    static func workspace(_ document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard) -> (MCPWorkspace, CenteredScreenshotsServices) {
        let screenshots = CenteredScreenshotsServices(document: document)
        var storePage = DebugStorePageServices()
        storePage.screenshots = screenshots
        return (MCPTestFixtures.workspace(storePage: storePage), screenshots)
    }

    /// Calls `tool` as Claude Code, on Lumen unless `arguments` names
    /// another app.
    static func call(_ tool: some MCPTool, _ arguments: [String: JSONValue] = [:], in workspace: MCPWorkspace) async throws -> MCPToolOutcome {
        var arguments = arguments
        if arguments["appId"] == nil { arguments["appId"] = .string(appID) }
        return try await tool.call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace, clientName: "Claude Code"))
    }

    /// The sample document with the stale p3 first and template v4 that
    /// narrowed the device.
    static var staleDocument: ScreenshotsDocument {
        var document = ScreenshotsDebugDocuments.standard
        document.history = ScreenshotsSampleData.staleHistory
        document.proposals.insert(ScreenshotsSampleData.staleProposal, at: 0)
        return document
    }
}
#endif
