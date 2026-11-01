//
//  MCPServerController+Launch.swift
//  AppLocalizer
//

import Foundation

/// The runs AppLocalizer starts itself (`ClaudeCodeLauncher`): they act as
/// the paired Claude Code, each with a token of its own that works only
/// until the run ends, so a run's token can never outlive it.
extension MCPServerController {
    /// The Claude Code pairing runs act as: the one paired last, else a new
    /// one, so Settings lists it and Revoke stops every run.
    func launchClientID() -> MCPPairedClient.ID? {
        if let client = pairedClients.last(where: { $0.kind == .claudeCode }) { return client.id }
        let client = MCPPairedClient(id: UUID(), kind: .claudeCode, name: MCPClientKind.claudeCode.title, pairedAt: now())
        let token = MCPAccessToken.generate()
        do {
            try secrets.setSecret(token, named: client.secretName)
        } catch {
            record(client: client.name, tool: "—", target: "", outcome: .refused, reason: error.localizedDescription)
            return nil
        }
        tokens[client.id] = token
        pairedClients.append(client)
        savePairedClients()
        return client.id
    }

    /// A new token for one run, acting as `clientID`.
    func issueRunToken(for clientID: MCPPairedClient.ID) -> String {
        let token = MCPAccessToken.generate()
        runTokens[token] = clientID
        return token
    }

    /// The run ended: its token stops working. Every request is checked
    /// against it, so whatever still carries it is refused from now on.
    func revokeRunToken(_ token: String) {
        runTokens[token] = nil
    }

    /// Turns the server on if it's off and waits until it listens, for up
    /// to `timeout`. Returns why it couldn't, or nil once it listens.
    func startForLaunch(timeout: Duration = .seconds(5)) async -> String? {
        if !isEnabled { setEnabled(true) }
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            switch status {
            case .listening: return nil
            case let .failed(message): return message
            case .off, .starting: try? await Task.sleep(for: .milliseconds(50))
            }
        }
        // The server's answer may have arrived while the main actor was busy.
        switch status {
        case .listening: return nil
        case let .failed(message): return message
        case .off, .starting: return String(localized: "It didn’t start in time.")
        }
    }
}
