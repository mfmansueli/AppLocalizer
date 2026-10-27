//
//  MCPToolContext.swift
//  AppLocalizer
//

import Foundation

/// Everything a tool call runs with: the open account and the client that
/// called, whose name tags its proposals.
@MainActor
struct MCPToolContext {
    var workspace: MCPWorkspace
    /// e.g. "Claude Code".
    var clientName: String

    /// The source of every change this call queues.
    var source: ChangeSource { .assistant(client: clientName) }
}
