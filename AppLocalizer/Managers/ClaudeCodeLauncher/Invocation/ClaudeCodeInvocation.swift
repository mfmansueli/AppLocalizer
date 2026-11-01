//
//  ClaudeCodeInvocation.swift
//  AppLocalizer
//

import Foundation

/// The arguments the helper passes to `claude` for one run: a print run in
/// the project folder that streams JSON, connects only to AppLocalizer's
/// server with a token made for this run, and is restricted to
/// `permissions`.
struct ClaudeCodeInvocation: Hashable, Sendable {
    /// Absolute path of the project folder.
    var workingDirectory: String
    var prompt: String
    var permissions: ClaudeCodePermissions
    var port: UInt16
    /// The run's own bearer token (`MCPServerController.issueRunToken`).
    var token: String
    /// The session's name in Claude Code's history, e.g. "AppLocalizer ·
    /// Suggest Everything · Lumen Journal".
    var sessionName: String

    /// `run <folder> -- <claude arguments>`, for the helper.
    var helperArguments: [String] {
        ["run", workingDirectory, "--"] + claudeArguments
    }

    var claudeArguments: [String] {
        [
            "-p", prompt,
            "--output-format", "stream-json",
            "--verbose",
            "--restricted",
            "--strict-mcp-config",
            "--mcp-config", mcpConfiguration,
            "--settings", settings,
            "--permission-mode", "dontAsk",
            "--append-system-prompt", permissions.systemPrompt,
            "--name", sessionName,
            // Variadic, so it goes last; an empty list turns every built-in
            // tool off.
            "--tools",
        ] + (permissions.tools.isEmpty ? [""] : permissions.tools)
    }

    /// `{"mcpServers":{"applocalizer":{"type":"http","url":…,"headers":…}}}`.
    var mcpConfiguration: String {
        let server: JSONValue = [
            "type": "http",
            "url": .string(MCPEndpoint.url(port: port)),
            "headers": ["Authorization": .string("Bearer \(token)")],
        ]
        let configuration: JSONValue = ["mcpServers": .object([MCPEndpoint.serverName: server])]
        return configuration.jsonString()
    }

    /// `{"permissions":{"allow":[…]}}`.
    var settings: String {
        let allow = permissions.allowRules(port: port).map(JSONValue.string)
        let settings: JSONValue = ["permissions": ["allow": .array(allow)]]
        return settings.jsonString()
    }
}
