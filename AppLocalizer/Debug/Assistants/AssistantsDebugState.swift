//
//  AssistantsDebugState.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Puts the MCP server into one of the design's states for DEBUG scenes:
/// off, pairing (before and after the command is copied), paired
/// assistants (one connected, one idle), one disconnected, or a log with
/// refused calls. Nothing listens on a port.
enum AssistantsDebugState {
    case off
    case pairing
    case pairingCopied
    case paired
    case disconnected
    case log

    @MainActor
    func apply(to server: MCPServerController) {
        guard self != .off else { return }
        server.setEnabled(true)
        switch self {
        case .off:
            break
        case .pairing:
            server.beginPairing(kind: .claudeCode)
        case .pairingCopied:
            server.beginPairing(kind: .claudeCode)
            server.markPairingCopied()
        case .paired:
            server.restorePairings([Self.claudeCode, Self.cursor], tokens: [:])
            server.sessions = [Self.session(lastActivity: Self.today(10, 43))]
        case .disconnected:
            var client = Self.claudeCode
            client.lastSeenAt = Self.today(10, 44)
            server.restorePairings([client], tokens: [:])
            server.seenThisLaunch = [client.id]
        case .log:
            server.restorePairings([Self.claudeCode], tokens: [:])
            server.sessions = [Self.session(lastActivity: Self.today(11, 42))]
            for line in Self.logLines.reversed() {
                server.record(client: line.client, tool: line.tool, target: line.target, outcome: line.outcome, reason: line.reason)
            }
        }
    }

    static let claudeCodeID = UUID(uuidString: "6C1E7C3A-2B11-4D0E-9C55-0A4F1B2C3D01") ?? UUID()

    static var claudeCode: MCPPairedClient {
        MCPPairedClient(
            id: claudeCodeID,
            kind: .claudeCode,
            name: "Claude Code",
            pairedAt: today(9, 30),
            lastSeenAt: today(10, 43),
            workingDirectory: "~/Developer/Lumen"
        )
    }

    static var cursor: MCPPairedClient {
        let october22 = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 16)) ?? .now
        return MCPPairedClient(
            id: UUID(uuidString: "6C1E7C3A-2B11-4D0E-9C55-0A4F1B2C3D02") ?? UUID(),
            kind: .cursor,
            name: "Cursor",
            pairedAt: october22,
            lastSeenAt: october22,
            workingDirectory: "~/Developer/Lumen-web"
        )
    }

    private static func session(lastActivity: Date) -> MCPClientSession {
        MCPClientSession(
            id: "debug-session",
            pairedClientID: claudeCodeID,
            clientName: "claude-code",
            clientVersion: "2.1.0",
            displayName: "Claude Code",
            protocolVersion: MCPProtocolVersion.latest,
            supportsRoots: true,
            connectedAt: today(10, 40),
            lastActivity: lastActivity,
            hasOpenStream: true,
            workingDirectory: "~/Developer/Lumen"
        )
    }

    private static func today(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    private static let logLines = [
        line("propose_listing_text", "Lumen Journal · ko · Description", .proposed),
        line("propose_listing_text", "Lumen Journal · de-DE · Subtitle", .refused, "34 characters; the limit is 30. Shorten it and propose again."),
        line("propose_prices", "Tempo Metronome · Annual", .refused, "Tempo is set to Keep my prices, so price proposals are off for this app."),
        line("propose_prices", "Lumen Journal · Annual · BR", .refused, "R$ 112,00 isn’t a price point. Nearest: R$ 109,90 or R$ 114,90."),
        line("list_missing_translations", "Lumen Journal · version 1.4", .read),
        line("list_apps", "Northpier Studio · 6 apps", .read),
    ]

    private static func line(_ tool: String, _ target: String, _ outcome: MCPCallOutcome, _ reason: String? = nil) -> MCPLogEntry {
        MCPLogEntry(date: .now, client: "Claude Code", tool: tool, target: target, outcome: outcome, reason: reason)
    }
}
#endif
