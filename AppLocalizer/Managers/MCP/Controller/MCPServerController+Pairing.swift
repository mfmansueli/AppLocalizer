//
//  MCPServerController+Pairing.swift
//  AppLocalizer
//

import Foundation

/// Pairing: each assistant gets its own token (or redeems a six-digit code
/// for one), becomes an `MCPPairedClient` on its first request, and keeps
/// working until the person revokes it. Tokens live in the Keychain; the
/// list of clients in `UserDefaults`.
extension MCPServerController {
    // MARK: - The pairing sheet

    /// Opens a pairing: a new token for this client only, and a code.
    func beginPairing(kind: MCPClientKind = .claudeCode) {
        pendingPairing = MCPPendingPairing(
            clientID: UUID(),
            kind: kind,
            token: MCPAccessToken.generate(),
            code: .generate(now: now())
        )
    }

    /// Another client in the sheet's picker; the token stays the same.
    func choosePairingKind(_ kind: MCPClientKind) {
        guard pendingPairing?.isConnected == false else { return }
        pendingPairing?.kind = kind
        pendingPairing?.isWaiting = false
    }

    /// The snippet the sheet shows for the pending pairing.
    var pairingSnippet: String? {
        guard let pairing = pendingPairing else { return nil }
        return pairing.kind.setupSnippet(token: pairing.token, url: url, bridgePath: bridgePath)
    }

    /// The person copied the snippet: the sheet waits for the client.
    func markPairingCopied() {
        pendingPairing?.isWaiting = true
    }

    /// Cancel: a client that never connected isn't paired, and its token
    /// stops working.
    func cancelPairing() {
        pendingPairing = nil
    }

    /// Done, after the client connected.
    func finishPairing() {
        pendingPairing = nil
    }

    /// "Finish Without Testing": the client keeps its token and counts as
    /// paired, and the Assistant button waits for its first call.
    func finishPairingWithoutTesting() {
        if pendingPairing?.isConnected == false { _ = completePairing() }
        pendingPairing = nil
    }

    /// Revoke: the client is disconnected now and its token stops working.
    func revoke(_ clientID: MCPPairedClient.ID) {
        for session in sessions where session.pairedClientID == clientID {
            disconnect(session.id)
        }
        if let client = pairedClients.first(where: { $0.id == clientID }) {
            try? secrets.setSecret(nil, named: client.secretName)
        }
        tokens[clientID] = nil
        seenThisLaunch.remove(clientID)
        pairedClients.removeAll { $0.id == clientID }
        savePairedClients()
    }

    func status(of client: MCPPairedClient) -> MCPPairedClientStatus {
        if let lastCall = sessions.filter({ $0.pairedClientID == client.id }).map(\.lastActivity).max() {
            return .connected(lastCall: lastCall)
        }
        if seenThisLaunch.contains(client.id), let lastSeen = client.lastSeenAt {
            return .disconnected(lastSeen: lastSeen)
        }
        return .idle(since: client.lastSeenAt ?? client.pairedAt, everConnected: client.lastSeenAt != nil)
    }

    // MARK: - Requests

    /// The paired client whose token an `Authorization` header carries. The
    /// pending pairing's token pairs its client on the spot.
    func authorizedClientID(for header: String?) -> MCPPairedClient.ID? {
        guard let credential = MCPAccessToken.bearer(in: header) else { return nil }
        if let match = tokens.first(where: { MCPAccessToken.matches(credential, token: $0.value) }) {
            return match.key
        }
        guard let pairing = pendingPairing, !pairing.isConnected, MCPAccessToken.matches(credential, token: pairing.token) else {
            return nil
        }
        return completePairing()
    }

    /// `POST /mcp/pair` with `{"code": "482913"}`: the pending pairing's
    /// token, once, for clients that asked the person for a code. Wrong codes
    /// count toward voiding it.
    func redeemPairingCode(_ code: String) -> String? {
        guard var pairing = pendingPairing, !pairing.isConnected, pairing.code.isUsable(at: now()) else { return nil }
        guard pairing.code.matches(code) else {
            pairing.code.failedAttempts += 1
            pendingPairing = pairing
            return nil
        }
        // Single use: the token is what connects from now on.
        pairing.code.expiresAt = now()
        pairing.isWaiting = true
        pendingPairing = pairing
        return pairing.token
    }

    /// A paired client sent a request at `date`: remembered for its row.
    func noteSeen(_ clientID: MCPPairedClient.ID, at date: Date, workingDirectory: String? = nil) {
        guard let index = pairedClients.firstIndex(where: { $0.id == clientID }) else { return }
        seenThisLaunch.insert(clientID)
        pairedClients[index].lastSeenAt = date
        if let workingDirectory { pairedClients[index].workingDirectory = workingDirectory }
        savePairedClients()
    }

    /// The first `initialize` of an "Other" client names it.
    func nameClient(_ clientID: MCPPairedClient.ID, from session: MCPClientSession) {
        guard let index = pairedClients.firstIndex(where: { $0.id == clientID }), pairedClients[index].kind == .other else { return }
        pairedClients[index].name = session.displayName
        savePairedClients()
    }

    /// The pending client connected (or the person finished without
    /// testing): it's paired from now on.
    private func completePairing() -> MCPPairedClient.ID? {
        guard var pairing = pendingPairing else { return nil }
        let client = MCPPairedClient(id: pairing.clientID, kind: pairing.kind, name: pairing.kind.title, pairedAt: now())
        do {
            try secrets.setSecret(pairing.token, named: client.secretName)
        } catch {
            record(client: client.name, tool: "—", target: "", outcome: .refused, reason: error.localizedDescription)
            return nil
        }
        tokens[client.id] = pairing.token
        pairedClients.append(client)
        savePairedClients()
        pairing.connectedClient = client
        pendingPairing = pairing
        return client.id
    }

    // MARK: - Storage

    func loadPairedClients() {
        guard let data = defaults?.data(forKey: Key.pairedClients),
              let clients = try? JSONDecoder().decode([MCPPairedClient].self, from: data) else { return }
        pairedClients = clients
        for client in clients {
            tokens[client.id] = try? secrets.secret(named: client.secretName)
        }
    }

    /// Restores pairings in memory, for DEBUG scenes and tests.
    func restorePairings(_ clients: [MCPPairedClient], tokens clientTokens: [MCPPairedClient.ID: String]) {
        pairedClients = clients
        tokens = clientTokens
    }

    func savePairedClients() {
        guard let defaults, let data = try? JSONEncoder().encode(pairedClients) else { return }
        defaults.set(data, forKey: Key.pairedClients)
    }
}
