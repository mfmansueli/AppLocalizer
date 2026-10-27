//
//  MCPPendingPairing.swift
//  AppLocalizer
//

import Foundation

/// The pairing the "Pair an assistant" sheet is showing: a token made for
/// this client only, and a pairing code. It becomes an `MCPPairedClient`
/// when the client first connects with either; Cancel throws both away.
struct MCPPendingPairing: Hashable, Sendable {
    var clientID: UUID
    var kind: MCPClientKind
    var token: String
    var code: MCPPairingCode
    /// Whether the person copied the snippet, so the sheet says it's waiting.
    var isWaiting = false
    /// Set once the client connected; the sheet then says from where.
    var connectedClient: MCPPairedClient?

    var isConnected: Bool { connectedClient != nil }
}
