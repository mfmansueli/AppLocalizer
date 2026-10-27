//
//  MCPClientSession.swift
//  AppLocalizer
//

import Foundation

/// An assistant connected to the server: one MCP session, from its
/// `initialize` until it goes away or the person revokes its pairing.
struct MCPClientSession: Identifiable, Hashable, Sendable {
    /// The `Mcp-Session-Id` the server gave it.
    var id: String
    /// The pairing whose token opened it.
    var pairedClientID: UUID
    /// `clientInfo.name` as sent, e.g. "claude-code".
    var clientName: String
    var clientVersion: String?
    /// e.g. "Claude Code"; proposals carry it as their source tag.
    var displayName: String
    var protocolVersion: String
    /// Whether it can tell the server its project folder (MCP roots).
    var supportsRoots: Bool
    var connectedAt: Date
    var lastActivity: Date
    /// Its event stream is open, so it's surely still there.
    var hasOpenStream = false
    /// The project folder it works in, e.g. "~/Developer/Lumen", when it
    /// shared one.
    var workingDirectory: String?

    var monogram: String {
        ChangeSource.assistant(client: displayName).monogram ?? "AI"
    }

    /// The name people know a client by, from what it sends in `clientInfo`.
    static func displayName(clientName: String, title: String?) -> String {
        MCPClientKind.matching(clientName: clientName)?.title ?? title ?? clientName
    }

    /// A root's `file://` URI as a path with the home folder shortened to
    /// "~", the way Terminal shows it.
    static func displayPath(forRootURI uri: String, homeDirectory: String) -> String? {
        guard let url = URL(string: uri), url.isFileURL else { return nil }
        let path = url.path(percentEncoded: false)
        let home = homeDirectory.hasSuffix("/") ? String(homeDirectory.dropLast()) : homeDirectory
        guard !home.isEmpty, path == home || path.hasPrefix(home + "/") else { return path }
        return "~" + path.dropFirst(home.count)
    }
}
