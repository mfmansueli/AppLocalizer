//
//  MCPClientKind.swift
//  AppLocalizer
//

import Foundation

/// The assistants "Pair Assistant…" knows how to set up, each with the
/// snippet that carries its own token and where that snippet goes.
enum MCPClientKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case claudeCode
    case claudeDesktop
    case cursor
    case codex
    case other

    var id: Self { self }

    /// e.g. "Claude Code"; proposals carry it as their source tag.
    var title: String {
        switch self {
        case .claudeCode: "Claude Code"
        case .claudeDesktop: "Claude Desktop"
        case .cursor: "Cursor"
        case .codex: "Codex"
        case .other: String(localized: "MCP client")
        }
    }

    /// The segment in the pairing sheet.
    var pickerTitle: String {
        self == .other ? String(localized: "Other") : title
    }

    /// Where the snippet goes.
    var setupLocation: String {
        switch self {
        case .claudeCode: String(localized: "Run in Terminal, in your project folder.")
        case .claudeDesktop: String(localized: "Claude Desktop → Settings → Developer → Edit Config, under “mcpServers”.")
        case .cursor: String(localized: ".cursor/mcp.json in your project, under “mcpServers”.")
        case .codex: "~/.codex/config.toml"
        case .other: String(localized: "Any MCP client that speaks Streamable HTTP.")
        }
    }

    /// Clients that launch servers as processes go through the stdio bridge
    /// in the app bundle; the others connect over HTTP directly.
    var usesBridge: Bool {
        self == .claudeDesktop || self == .codex
    }

    /// The command or configuration that connects this client with `token`.
    func setupSnippet(token: String, url: String, bridgePath: String) -> String {
        let server = MCPEndpoint.serverName
        switch self {
        case .claudeCode:
            return "claude mcp add --transport http \(server) \(url) --header \"Authorization: Bearer \(token)\""
        case .claudeDesktop:
            return """
            "\(server)": {
              "command": "\(bridgePath)",
              "args": ["--token", "\(token)"]
            }
            """
        case .cursor:
            return """
            "\(server)": {
              "url": "\(url)",
              "headers": { "Authorization": "Bearer \(token)" }
            }
            """
        case .codex:
            return """
            [mcp_servers.\(server)]
            command = "\(bridgePath)"
            args = ["--token", "\(token)"]
            """
        case .other:
            return """
            URL     \(url)
            Header  Authorization: Bearer \(token)
            """
        }
    }

    /// The kind a connecting client's `clientInfo.name` suggests.
    static func matching(clientName: String) -> MCPClientKind? {
        let name = clientName.lowercased()
        // Claude Code's own sessions and agents add to the name:
        // "claude-code-motivator".
        if name == "claude-code" || name.hasPrefix("claude-code-") { return .claudeCode }
        if name == "claude-ai" || name == "claude desktop" { return .claudeDesktop }
        if name.hasPrefix("cursor") { return .cursor }
        if name.hasPrefix("codex") { return .codex }
        return nil
    }
}
