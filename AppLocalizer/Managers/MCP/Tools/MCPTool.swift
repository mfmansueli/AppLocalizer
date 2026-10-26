//
//  MCPTool.swift
//  AppLocalizer
//

import Foundation

/// One tool an assistant can call. Tools read through the workspace's
/// services and propose by queueing `PendingChange`s tagged with the client
/// (`ChangeSource.assistant`), validated exactly like a manual edit.
@MainActor
protocol MCPTool {
    var definition: MCPToolDefinition { get }

    /// Runs the call. Throwing `MCPToolError` (or any error) answers with
    /// an error result and logs the call as refused.
    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome
}
