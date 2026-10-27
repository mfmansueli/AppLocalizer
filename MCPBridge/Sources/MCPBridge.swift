//
//  MCPBridge.swift
//  applocalizer-mcp
//

import Foundation

/// Forwards an MCP client's stdio to AppLocalizer's Streamable HTTP endpoint,
/// for clients that only launch servers as processes (Claude Desktop, Codex).
/// Each line read is POSTed with the pairing token, and each reply becomes
/// the lines to write back. When AppLocalizer relaunched and forgot the
/// session, the client's `initialize` is replayed so the client never
/// notices.
actor MCPBridge {
    /// One HTTP reply, as far as the bridge reads it.
    private struct Reply {
        var status: Int
        var contentType: String
        var body: Data
        var sessionID: String?

        var isSuccess: Bool { (200..<300).contains(status) }
    }

    /// The JSON-RPC code of the errors the bridge itself answers with.
    static let failureCode = -32000

    private let options: MCPBridgeOptions
    private let transport: any MCPBridgeTransport
    private let log: @Sendable (String) -> Void
    /// AppLocalizer's session, from the `initialize` reply.
    private(set) var sessionID: String?
    private var protocolVersion: String?
    /// The client's `initialize`, replayed to start a new session.
    private var initializeBody: Data?

    /// `log` gets what the client shouldn't see (the tool writes it to stderr).
    init(options: MCPBridgeOptions, transport: any MCPBridgeTransport, log: @escaping @Sendable (String) -> Void = { _ in }) {
        self.options = options
        self.transport = transport
        self.log = log
    }

    /// What to write to stdout for one line read from stdin.
    func forward(_ line: String) async -> [String] {
        guard let message = MCPBridgeMessage(line: line) else {
            return [MCPBridgeMessage.error(id: nil, code: -32700, message: "Parse error: write one JSON-RPC message per line.")]
        }
        if message.isInitialize {
            sessionID = nil
            protocolVersion = nil
            initializeBody = message.body
        }
        do {
            var reply = try await post(message.body)
            if message.isInitialize {
                remember(reply)
            } else if reply.status == 404, try await startNewSession() {
                reply = try await post(message.body)
            }
            return lines(for: reply, answering: message)
        } catch {
            log("Can’t reach \(options.url.absoluteString): \(error.localizedDescription)")
            guard message.isRequest else { return [] }
            return [MCPBridgeMessage.error(id: message.idJSON, code: Self.failureCode, message: Self.unreachable)]
        }
    }

    /// Ends the session once the client closed stdin.
    func close() async {
        guard sessionID != nil else { return }
        _ = try? await transport.send(request(method: "DELETE"))
        sessionID = nil
    }

    // MARK: - HTTP

    private func post(_ body: Data) async throws -> Reply {
        var request = request(method: "POST")
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        let (data, response) = try await transport.send(request)
        return Reply(
            status: response.statusCode,
            contentType: response.value(forHTTPHeaderField: "Content-Type") ?? "",
            body: data,
            sessionID: response.value(forHTTPHeaderField: "Mcp-Session-Id")
        )
    }

    private func request(method: String) -> URLRequest {
        // Tool calls can wait on App Store Connect.
        var request = URLRequest(url: options.url, timeoutInterval: 300)
        request.httpMethod = method
        request.setValue("Bearer \(options.token)", forHTTPHeaderField: "Authorization")
        if let sessionID { request.setValue(sessionID, forHTTPHeaderField: "Mcp-Session-Id") }
        if let protocolVersion { request.setValue(protocolVersion, forHTTPHeaderField: "MCP-Protocol-Version") }
        return request
    }

    // MARK: - Sessions

    /// Keeps the session and protocol version an `initialize` reply set.
    private func remember(_ reply: Reply) {
        guard reply.isSuccess else { return }
        sessionID = reply.sessionID
        protocolVersion = messages(in: reply).first.flatMap(Self.protocolVersion(in:))
    }

    /// AppLocalizer answered 404 because it relaunched or the session went
    /// quiet: replays `initialize` and `notifications/initialized`. False
    /// when there was no session to replace, or a new one didn't start.
    private func startNewSession() async throws -> Bool {
        guard sessionID != nil, let initializeBody else { return false }
        log("AppLocalizer forgot the session; starting a new one.")
        sessionID = nil
        protocolVersion = nil
        try await remember(post(initializeBody))
        guard sessionID != nil else { return false }
        _ = try await post(Data(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#.utf8))
        return true
    }

    // MARK: - Replies

    private func lines(for reply: Reply, answering message: MCPBridgeMessage) -> [String] {
        let messages = messages(in: reply)
        // AppLocalizer answers bad messages with a JSON-RPC error and a 4xx.
        if reply.isSuccess || (!messages.isEmpty && messages.allSatisfy(Self.isJSONRPC)) { return messages }
        let text = String(bytes: reply.body, encoding: .utf8) ?? ""
        log("AppLocalizer answered \(reply.status): \(text)")
        guard message.isRequest else { return [] }
        return [MCPBridgeMessage.error(id: message.idJSON, code: Self.failureCode, message: Self.explanation(status: reply.status, text: text))]
    }

    private func messages(in reply: Reply) -> [String] {
        if reply.contentType.hasPrefix("text/event-stream") { return MCPBridgeEventStream.messages(in: reply.body) }
        guard reply.contentType.hasPrefix("application/json"), !reply.body.isEmpty else { return [] }
        return [Self.oneLine(reply.body)]
    }

    /// stdio carries one message per line, so pretty-printed JSON is
    /// compacted.
    private static func oneLine(_ json: Data) -> String {
        guard json.contains(UInt8(ascii: "\n")),
              let object = try? JSONSerialization.jsonObject(with: json),
              let compact = try? JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes])
        else { return String(bytes: json, encoding: .utf8) ?? "" }
        return String(bytes: compact, encoding: .utf8) ?? ""
    }

    private static func isJSONRPC(_ line: String) -> Bool {
        (try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])?["jsonrpc"] != nil
    }

    private static func protocolVersion(in line: String) -> String? {
        let object = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
        return (object?["result"] as? [String: Any])?["protocolVersion"] as? String
    }

    // MARK: - Failures

    static let unreachable = "Can’t reach AppLocalizer. Open it and turn on Settings → AI Assistants → Local MCP server."

    private static func explanation(status: Int, text: String) -> String {
        switch status {
        case 401:
            "AppLocalizer didn’t accept this token. Pair the assistant again in AppLocalizer → Settings → AI Assistants and use the new token."
        default:
            "AppLocalizer answered \(status): \(text)"
        }
    }
}
