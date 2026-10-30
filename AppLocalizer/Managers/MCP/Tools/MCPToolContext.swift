//
//  MCPToolContext.swift
//  AppLocalizer
//

import Foundation

/// Everything a tool call runs with: the open account, the client that
/// called (whose name tags its proposals), and what the person lets
/// assistants do, for tools that check per item (`suggest_fields`).
@MainActor
struct MCPToolContext {
    var workspace: MCPWorkspace
    /// e.g. "Claude Code".
    var clientName: String
    var allowedProposals: Set<MCPProposalKind> = Set(MCPProposalKind.allCases)
    /// "Suggest and edit drafts": `suggest_fields` may write the value as an
    /// unpushed change (`apply: true`).
    var editsDrafts = false

    func allows(_ kind: MCPProposalKind) -> Bool {
        allowedProposals.contains(kind)
    }

    /// The source of every change this call queues.
    var source: ChangeSource { .assistant(client: clientName) }
}
