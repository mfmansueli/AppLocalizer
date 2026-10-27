//
//  FakeMCPTool.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// A tool with a given name and proposal kind that answers `outcome` and
/// counts its calls.
@MainActor
final class FakeMCPTool: MCPTool {
    let definition: MCPToolDefinition
    var outcome: MCPToolOutcome
    var error: (any Error)?
    private(set) var calls: [MCPToolArguments] = []

    init(name: String, proposalKind: MCPProposalKind? = nil, outcome: MCPToolOutcome = .queued(changeID: "change-1", target: "Lumen Journal")) {
        definition = MCPToolDefinition(
            name: name,
            title: name,
            description: "A fake \(name).",
            inputSchema: MCPToolDefinition.schema(["appId": MCPToolDefinition.string("The app.")]),
            proposalKind: proposalKind
        )
        self.outcome = outcome
    }

    func call(_ arguments: MCPToolArguments, in _: MCPToolContext) async throws -> MCPToolOutcome {
        calls.append(arguments)
        if let error { throw error }
        return outcome
    }
}
