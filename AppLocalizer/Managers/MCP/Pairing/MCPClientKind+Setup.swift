//
//  MCPClientKind+Setup.swift
//  AppLocalizer
//

import Foundation

/// How "Set Up Your AI Assistant" presents each client: its name in the
/// list, what it can see, and what to tell the person next to the snippet.
extension MCPClientKind {
    /// "Codex CLI", "Other MCP client".
    var setupName: String {
        switch self {
        case .codex: "Codex CLI"
        case .other: String(localized: "Other MCP client")
        default: title
        }
    }

    var setupDescription: String {
        switch self {
        case .claudeCode:
            String(localized: "Works in your project folder, so it can read the code and git history. Best for What’s New, review notes and privacy answers.")
        case .claudeDesktop:
            String(localized: "Uses AppLocalizer’s data plus whatever you attach or paste. It doesn’t see your code unless you give it access.")
        case .cursor: String(localized: "Works with the project you have open in Cursor.")
        case .codex: String(localized: "Reads the project you start it in.")
        case .other: String(localized: "Any client that can connect to a local MCP server.")
        }
    }

    /// The line above the snippet.
    var setupIntro: String {
        switch self {
        case .claudeCode: String(localized: "In Terminal, go to your app’s project folder and run:")
        case .claudeDesktop:
            String(localized: """
            In Claude Desktop, choose Settings → Developer → Edit Config, add this under “mcpServers” in \
            claude_desktop_config.json, then restart Claude Desktop:
            """)
        case .cursor: String(localized: "In Cursor, add this under “mcpServers” in .cursor/mcp.json, or use Settings → MCP → Add New Server:")
        case .codex: String(localized: "Add this to ~/.codex/config.toml:")
        case .other: String(localized: "Add a server to your client with this address and header:")
        }
    }

    /// The note under the snippet.
    var setupNote: String {
        switch self {
        case .claudeCode:
            String(localized: "Adding it from the project folder lets Claude Code read your code. To use AppLocalizer in every project, add --scope user.")
        case .claudeDesktop:
            String(localized: """
            Claude Desktop doesn’t see your code unless you give it access, so suggestions written from code \
            (What’s New, privacy) work best from Claude Code.
            """)
        case .cursor: String(localized: "Open your app’s folder in Cursor so its agent can read the code.")
        case .codex: String(localized: "Start Codex in your app’s project folder so it can read the code.")
        case .other: String(localized: "Your client needs MCP tools. AppLocalizer also offers MCP prompts, if your client shows them.")
        }
    }

    /// "Copy Command", or "Copy Configuration" for a file.
    var copyTitle: String {
        self == .claudeCode ? String(localized: "Copy Command") : String(localized: "Copy Configuration")
    }
}
