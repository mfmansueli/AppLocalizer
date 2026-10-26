//
//  MCPEndpoint.swift
//  AppLocalizer
//

import Foundation

/// Where the MCP server listens and what it calls itself.
enum MCPEndpoint {
    static let host = "127.0.0.1"
    static let defaultPort: UInt16 = 47321
    static let path = "/mcp"
    /// The name assistants show for the server, as in `mcp__applocalizer__…`.
    static let serverName = "applocalizer"

    static func url(port: UInt16) -> String {
        "http://\(host):\(port)\(path)"
    }

    /// "127.0.0.1:47321", as Settings shows it.
    static func address(port: UInt16) -> String {
        "\(host):\(port)"
    }

    /// What `initialize` tells the assistant about the server.
    static let instructions = """
    AppLocalizer manages the App Store Connect data of the person's apps: store listings, subscription prices \
    and app information. Read with the list_ and get_ tools. Change things with the propose_ tools: each \
    proposal is validated like a manual edit and queued in AppLocalizer, where the person reviews and pushes \
    it. You can't push, and nothing reaches App Store Connect until the person does. When a proposal is \
    refused, the reason says how to fix it. Always tell the person what you couldn't see.
    """
}
