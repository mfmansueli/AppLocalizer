//
//  MCPServerController.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The local MCP server behind Settings → AI Assistants: whether it runs,
/// the paired assistants and their sessions, what they may propose, and the
/// activity log. It's off until the person turns it on, listens only on
/// 127.0.0.1, and answers requests (`handle(_:)`, in
/// `MCPServerController+HTTP`) with the tools of `toolbox` acting on
/// `workspace`. Every assistant is paired with its own token
/// (`MCPServerController+Pairing`), so each can be revoked alone.
@MainActor
@Observable
final class MCPServerController {
    private(set) var isEnabled: Bool
    private(set) var status: MCPServerStatus = .off
    /// Open sessions, oldest first.
    var sessions: [MCPClientSession] = []
    /// Newest first, at most `logLimit` lines.
    private(set) var log: [MCPLogEntry] = []
    /// Paired assistants, in the order they were paired.
    var pairedClients: [MCPPairedClient] = []
    /// The pairing the "Pair an assistant" sheet shows, if it's open.
    var pendingPairing: MCPPendingPairing?
    /// Whether an assistant made a call in the last few seconds; the
    /// toolbar indicator spins while it does.
    private(set) var isWorking = false
    /// The assistant that made the latest call, e.g. "Claude Code".
    private(set) var workingClient: String?

    /// What assistants may propose; reading is always allowed.
    var allowedProposals: Set<MCPProposalKind> {
        didSet { defaults?.set(allowedProposals.map(\.rawValue).sorted(), forKey: Key.allowedProposals) }
    }

    /// The open account; `MainView` sets it, and tools answer "not
    /// connected" without it.
    var workspace: MCPWorkspace?
    var toolbox: MCPToolbox

    let port: UInt16
    static let logLimit = 200
    /// An assistant without an open stream counts as gone after this long
    /// without a request.
    static let idleTimeout: TimeInterval = 30 * 60
    /// How long after its last call an assistant still counts as working.
    static let workingInterval: Duration = .seconds(6)

    private let server: any LocalHTTPServing
    let secrets: any SecretStore
    let defaults: UserDefaults?
    let now: () -> Date
    let homeDirectory: String
    /// Where the stdio bridge for Claude Desktop and Codex lives.
    let bridgePath: String
    /// Each paired client's token, read from the Keychain once.
    var tokens: [MCPPairedClient.ID: String] = [:]
    /// Clients that connected since AppLocalizer opened, so a quiet one reads
    /// "Disconnected" rather than "not connected since".
    var seenThisLaunch: Set<MCPPairedClient.ID> = []
    /// Each session's open event stream, with a token telling a replaced
    /// stream's late close apart from the current one's.
    var streams: [String: (token: UUID, continuation: AsyncStream<String>.Continuation)] = [:]
    /// `roots/list` requests sent to clients, by request ID → session ID.
    var pendingRootRequests: [String: String] = [:]
    private var keepAliveTask: Task<Void, Never>?
    private var workingTask: Task<Void, Never>?

    /// `defaults` nil keeps the switch, pairings and permissions in memory
    /// (DEBUG scenes, tests).
    init(
        server: any LocalHTTPServing,
        secrets: any SecretStore,
        defaults: UserDefaults? = nil,
        port: UInt16 = MCPEndpoint.defaultPort,
        toolbox: MCPToolbox = .standard,
        homeDirectory: String = MCPServerController.userHomeDirectory,
        bridgePath: String = MCPEndpoint.bridgePath,
        now: @escaping () -> Date = Date.init
    ) {
        self.server = server
        self.secrets = secrets
        self.defaults = defaults
        self.port = port
        self.toolbox = toolbox
        self.homeDirectory = homeDirectory
        self.bridgePath = bridgePath
        self.now = now
        isEnabled = defaults?.bool(forKey: Key.isEnabled) ?? false
        allowedProposals = defaults?.stringArray(forKey: Key.allowedProposals)
            .map { Set($0.compactMap(MCPProposalKind.init(rawValue:))) } ?? Set(MCPProposalKind.allCases)
        loadPairedClients()
    }

    // MARK: - Reading

    var isRunning: Bool {
        if case .listening = status { return true }
        return false
    }

    var address: String { MCPEndpoint.address(port: port) }
    var url: String { MCPEndpoint.url(port: port) }

    /// Paired assistants with a session open.
    var connectedClients: [MCPPairedClient] {
        pairedClients.filter { client in sessions.contains { $0.pairedClientID == client.id } }
    }

    /// "Off", "Running · no assistant connected · 127.0.0.1:47321" or
    /// "Running · 1 assistant connected · 127.0.0.1:47321".
    var statusText: String {
        switch status {
        case .off: String(localized: "Off")
        case .starting: String(localized: "Starting…")
        case let .failed(message): String(localized: "Couldn’t start: \(message)")
        case .listening where connectedClients.isEmpty: String(localized: "Running · no assistant connected · \(address)")
        case .listening: String(localized: "Running · \(connectedClients.count) assistant connected · \(address)")
        }
    }

    func allows(_ kind: MCPProposalKind) -> Bool {
        allowedProposals.contains(kind)
    }

    /// The prompts whose tools are all offered.
    var availablePrompts: [MCPPrompt] {
        MCPPrompt.allCases.filter { $0.requiredTools.isSubset(of: toolbox.toolNames) }
    }

    // MARK: - Changing

    /// At launch: starts the server if the person left it on.
    func startIfEnabled() {
        if isEnabled { start() }
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        defaults?.set(enabled, forKey: Key.isEnabled)
        if enabled { start() } else { stop() }
    }

    func setAllowed(_ kind: MCPProposalKind, _ allowed: Bool) {
        if allowed { allowedProposals.insert(kind) } else { allowedProposals.remove(kind) }
    }

    /// Ends a session; the client's next request must start a new one.
    func disconnect(_ sessionID: MCPClientSession.ID) {
        streams.removeValue(forKey: sessionID)?.continuation.finish()
        if let session = sessions.first(where: { $0.id == sessionID }) {
            noteSeen(session.pairedClientID, at: session.lastActivity)
        }
        sessions.removeAll { $0.id == sessionID }
        pendingRootRequests = pendingRootRequests.filter { $0.value != sessionID }
    }

    func clearLog() {
        log = []
    }

    func record(client: String, tool: String, target: String, outcome: MCPCallOutcome, reason: String? = nil) {
        let entry = MCPLogEntry(date: now(), client: client, tool: tool, target: target, outcome: outcome, reason: reason)
        log.insert(entry, at: 0)
        if log.count > Self.logLimit { log.removeLast(log.count - Self.logLimit) }
    }

    /// Forgets sessions that went quiet without an open stream.
    func pruneIdleSessions() {
        let cutoff = now().addingTimeInterval(-Self.idleTimeout)
        for session in sessions where !session.hasOpenStream && session.lastActivity < cutoff {
            disconnect(session.id)
        }
    }

    /// A tool call from `client` just arrived: the toolbar shows it working
    /// for a few seconds (`interval`; DEBUG scenes keep it longer).
    func noteWorking(client: String, for interval: Duration = workingInterval) {
        workingClient = client
        isWorking = true
        workingTask?.cancel()
        workingTask = Task { [weak self] in
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            self?.isWorking = false
        }
    }

    // MARK: - Server

    private func start() {
        status = .starting
        server.start(
            port: port,
            handler: { [weak self] request in
                guard let self else { return .response(.text(503)) }
                return await handle(request)
            },
            onEvent: { [weak self] event in
                Task { @MainActor in self?.serverDidChange(event) }
            }
        )
    }

    private func stop() {
        server.stop()
        disconnectAll()
        cancelPairing()
        keepAliveTask?.cancel()
        keepAliveTask = nil
        status = .off
    }

    private func serverDidChange(_ event: LocalHTTPServerEvent) {
        guard isEnabled else { return }
        switch event {
        case let .ready(port):
            status = .listening(port: port)
            startKeepAlive()
        case let .failed(message):
            status = .failed(message: message)
            disconnectAll()
        }
    }

    func disconnectAll() {
        for session in sessions {
            disconnect(session.id)
        }
    }

    /// Every 25 seconds: a comment on each open stream, so idle connections
    /// stay open, and forgetting clients that went away.
    private func startKeepAlive() {
        keepAliveTask?.cancel()
        keepAliveTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                guard let self, !Task.isCancelled else { return }
                for stream in streams.values {
                    stream.continuation.yield(HTTPEventStream.keepAlive)
                }
                pruneIdleSessions()
            }
        }
    }

    /// The real home folder; inside the sandbox `NSHomeDirectory()` is the
    /// app's container.
    nonisolated static var userHomeDirectory: String {
        guard let entry = getpwuid(getuid()), let directory = entry.pointee.pw_dir else { return NSHomeDirectory() }
        return String(cString: directory)
    }

    enum Key {
        static let isEnabled = "mcp.isEnabled"
        static let allowedProposals = "mcp.allowedProposals"
        static let pairedClients = "mcp.pairedClients"
    }
}
