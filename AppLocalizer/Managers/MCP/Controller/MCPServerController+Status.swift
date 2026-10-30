//
//  MCPServerController+Status.swift
//  AppLocalizer
//

import Foundation

/// The person's own assistant, as the Assistant button and the overview
/// describe it: whether it's set up, which one, and what it did lately.
extension MCPServerController {
    var assistantStatus: AssistantStatus {
        let ready = keyAssistant?.clientName.map(AssistantStatus.ready)
        guard isEnabled else { return ready ?? .notSetUp }
        if let client = leadingClient, client.lastSeenAt != nil {
            return .connected(client: client.name)
        }
        if let pairing = pendingPairing {
            if let client = pairing.connectedClient { return .connected(client: client.name) }
            return ready ?? .waiting(client: pairing.kind.title)
        }
        if let client = leadingClient { return ready ?? .waiting(client: client.name) }
        return ready ?? .notSetUp
    }

    /// The assistant the button names: the one seen most recently, else
    /// the one paired last.
    var leadingClient: MCPPairedClient? {
        let seen = pairedClients.filter { $0.lastSeenAt != nil }
        if let latest = seen.max(by: { ($0.lastSeenAt ?? .distantPast) < ($1.lastSeenAt ?? .distantPast) }) { return latest }
        return pairedClients.last
    }

    /// `client`'s latest calls, newest first, one line per tool call.
    func recentCalls(of client: String, limit: Int = 3) -> [MCPLogEntry] {
        Array(log.filter { $0.client == client && $0.tool != "—" }.prefix(limit))
    }
}
