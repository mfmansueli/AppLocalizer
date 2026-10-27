//
//  MCPPairedClient.swift
//  AppLocalizer
//

import Foundation

/// An assistant paired in Settings → AI Assistants. Each has its own token
/// (in the Keychain, under `secretName`), so revoking one never touches the
/// others. Kept until the person revokes it.
struct MCPPairedClient: Identifiable, Hashable, Codable, Sendable {
    var id: UUID
    var kind: MCPClientKind
    /// e.g. "Claude Code"; for `.other`, the name the client sent when it
    /// first connected.
    var name: String
    var pairedAt: Date
    /// When it last sent a request, if it ever connected.
    var lastSeenAt: Date?
    /// The project folder it last worked in, e.g. "~/Developer/Lumen".
    var workingDirectory: String?

    /// The Keychain item holding its token.
    var secretName: String {
        "mcp.client.\(id.uuidString)"
    }

    var monogram: String {
        ChangeSource.assistant(client: name).monogram ?? "AI"
    }
}
