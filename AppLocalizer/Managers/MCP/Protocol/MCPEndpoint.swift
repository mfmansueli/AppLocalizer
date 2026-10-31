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
    /// Where a client trades a pairing code for its token.
    static let pairingPath = "/mcp/pair"
    /// The stdio bridge's name, in the app bundle's `Contents/MacOS`.
    static let bridgeName = "applocalizer-mcp"
    /// The name assistants show for the server, as in `mcp__applocalizer__…`.
    static let serverName = "applocalizer"

    /// Where Screenshot Autopilot's captures are uploaded: `POST
    /// /autopilot/<run token>` with the PNG as the body.
    static let autopilotPath = "/autopilot/"

    /// A run's upload link.
    static func autopilotUploadURL(port: UInt16, token: String) -> String {
        "http://\(host):\(port)\(autopilotPath)\(token)"
    }

    static func url(port: UInt16) -> String {
        "http://\(host):\(port)\(path)"
    }

    /// The stdio bridge Claude Desktop and Codex launch, inside this app.
    static var bridgePath: String {
        Bundle.main.bundleURL.appending(path: "Contents/MacOS/\(bridgeName)").path(percentEncoded: false)
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
    refused, the reason says how to fix it. Screenshot Autopilot runs are driven by you: once the person \
    starts one, call get_capture_plan, then next_step after each step until it says done. Always tell the \
    person what you couldn't see.
    """
}
