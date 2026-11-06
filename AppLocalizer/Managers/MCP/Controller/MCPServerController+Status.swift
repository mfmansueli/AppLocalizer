//
//  MCPServerController+Status.swift
//  AppLocalizer
//

import Foundation

/// The person's own assistant, as the Assistant button and the overview
/// describe it: whether it's set up, which one, and what it did lately.
extension MCPServerController {
    var assistantStatus: AssistantStatus {
        // AppLocalizer can start Claude Code whenever it's asked.
        if launcher?.canStart == true { return .connected(client: MCPClientKind.claudeCode.title) }
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

    /// The assistant Autopilot captures with: one connected now that can
    /// run Xcode, else Claude Code when AppLocalizer can start it. Right
    /// after AppLocalizer opens nothing is connected yet, and Screenshots
    /// said "Needs an assistant" while the toolbar said Claude Code was
    /// ready.
    var xcodeAssistant: String? {
        if let client = connectedClients.first(where: { $0.kind.canRunXcode }) { return client.name }
        return launcher?.canStart == true ? MCPClientKind.claudeCode.title : nil
    }

    /// The assistant the overview's card describes: Claude Code when
    /// AppLocalizer can start it (paired, or a stand-in until its first
    /// run pairs it), else the leading one.
    var assistantClient: MCPPairedClient? {
        guard launcher?.canStart == true else { return leadingClient }
        if let client = pairedClients.last(where: { $0.kind == .claudeCode }) { return client }
        return MCPPairedClient(id: Self.launchStandInID, kind: .claudeCode, name: MCPClientKind.claudeCode.title, pairedAt: now())
    }

    /// The stand-in's id, so views keep their identity.
    static let launchStandInID = UUID(uuidString: "0A11C0DE-0000-4000-8000-00000000C1A0") ?? UUID()

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
