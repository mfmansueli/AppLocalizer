//
//  MCPServerController+HTTP.swift
//  AppLocalizer
//

import Foundation

/// The Streamable HTTP endpoint: `POST /mcp` carries JSON-RPC messages,
/// `GET /mcp` opens a session's event stream and `DELETE /mcp` ends it.
/// Every request needs a local origin and a paired client's bearer token;
/// `POST /mcp/pair` trades a pairing code for that token.
extension MCPServerController {
    func handle(_ request: HTTPRequest) async -> HTTPReply {
        if request.path.hasPrefix(MCPEndpoint.autopilotPath) { return await .response(receiveAutopilotUpload(request)) }
        guard request.path == MCPEndpoint.path || request.path == MCPEndpoint.pairingPath else { return .response(.text(404)) }
        guard Self.isLocal(origin: request.header("origin")), Self.isLocal(host: request.header("host")) else {
            return .response(.text(403, "Only clients on this Mac may connect."))
        }
        if request.path == MCPEndpoint.pairingPath { return .response(redeem(request)) }
        guard let clientID = authorizedClientID(for: request.header("authorization")) else {
            recordUnauthorized()
            return .response(.text(401, "Wrong or missing access token.", headers: ["WWW-Authenticate": "Bearer"]))
        }
        pruneIdleSessions()
        switch request.method {
        case "POST": return await .response(post(request, from: clientID))
        case "GET": return openStream(request, from: clientID)
        case "DELETE": return .response(delete(request, from: clientID))
        default: return .response(.text(405, headers: ["Allow": "GET, POST, DELETE"]))
        }
    }

    // MARK: - Pairing code

    private func redeem(_ request: HTTPRequest) -> HTTPResponse {
        guard request.method == "POST" else { return .text(405, headers: ["Allow": "POST"]) }
        let body = try? JSONDecoder().decode(JSONValue.self, from: request.body)
        guard let code = body?["code"]?.stringValue, let token = redeemPairingCode(code) else {
            let reason = String(localized: "Wrong or expired pairing code. Open Settings → AI Assistants → Pair Assistant… for a new one.")
            record(client: String(localized: "Unknown client"), tool: "pair", target: "", outcome: .refused, reason: reason)
            let refusal: JSONValue = ["error": .string(reason)]
            return .json(refusal, status: 403)
        }
        let pairing: JSONValue = ["token": .string(token), "url": .string(url)]
        return .json(pairing)
    }

    // MARK: - POST

    private func post(_ request: HTTPRequest, from clientID: MCPPairedClient.ID) async -> HTTPResponse {
        guard let message = try? JSONDecoder().decode(JSONRPCMessage.self, from: request.body) else {
            let isBatch = (try? JSONDecoder().decode([JSONValue].self, from: request.body)) != nil
            let error = isBatch ? JSONRPCError.invalidRequest("Batched messages aren’t supported; send one message per request.") : .parseError
            return .json(JSONRPCResponse.error(error), status: 400)
        }
        guard let kind = message.kind else {
            return .json(JSONRPCResponse.error(.invalidRequest("Not a JSON-RPC 2.0 message."), id: message.id ?? .null), status: 400)
        }
        if kind == .request, message.method == "initialize" { return initialize(message, from: clientID) }
        if let version = request.header("mcp-protocol-version"), !MCPProtocolVersion.supported.contains(version) {
            return .text(400, "Unsupported MCP-Protocol-Version \(version).")
        }
        guard let sessionID = request.header("mcp-session-id") else {
            return .text(400, "Missing Mcp-Session-Id header; send initialize first.")
        }
        // A token can only use its own client's sessions.
        guard let index = sessions.firstIndex(where: { $0.id == sessionID && $0.pairedClientID == clientID }) else {
            return .text(404, "Unknown session; initialize again.")
        }
        sessions[index].lastActivity = now()
        let session = sessions[index]
        switch kind {
        case .notification:
            received(notification: message, from: session)
            return HTTPResponse(status: 202)
        case .response:
            received(response: message, from: session)
            return HTTPResponse(status: 202)
        case .request:
            return await .json(respond(to: message, from: session))
        }
    }

    private func initialize(_ message: JSONRPCMessage, from clientID: MCPPairedClient.ID) -> HTTPResponse {
        let params = message.params
        let version = MCPProtocolVersion.negotiated(requested: params?["protocolVersion"]?.stringValue)
        let info = params?["clientInfo"]
        let clientName = info?["name"]?.stringValue ?? "client"
        let session = MCPClientSession(
            id: UUID().uuidString,
            pairedClientID: clientID,
            clientName: clientName,
            clientVersion: info?["version"]?.stringValue,
            displayName: MCPClientSession.displayName(clientName: clientName, title: info?["title"]?.stringValue),
            protocolVersion: version,
            supportsRoots: params?["capabilities"]?["roots"] != nil,
            connectedAt: now(),
            lastActivity: now()
        )
        sessions.append(session)
        nameClient(clientID, from: session)
        noteSeen(clientID, at: session.connectedAt)
        record(client: session.displayName, tool: "initialize", target: "AppLocalizer MCP · protocol \(version)", outcome: .read)
        let result: JSONValue = [
            "protocolVersion": .string(version),
            "capabilities": ["tools": ["listChanged": false], "prompts": ["listChanged": false]],
            "serverInfo": ["name": .string(MCPEndpoint.serverName), "title": "AppLocalizer", "version": .string(Self.appVersion)],
            "instructions": .string(MCPEndpoint.instructions),
        ]
        return .json(JSONRPCResponse.result(result, id: message.id ?? .null), headers: ["Mcp-Session-Id": session.id])
    }

    private func respond(to message: JSONRPCMessage, from session: MCPClientSession) async -> JSONRPCResponse {
        let id = message.id ?? .null
        let params = message.params
        switch message.method ?? "" {
        case "ping":
            return .result([:], id: id)
        case "tools/list":
            return .result(toolbox.listResult, id: id)
        case "tools/call":
            return await callTool(params, from: session, id: id)
        case "prompts/list":
            return .result(["prompts": .array(availablePrompts.map(\.json))], id: id)
        case "prompts/get":
            guard let name = params?["name"]?.stringValue, let prompt = MCPPrompt(rawValue: name), availablePrompts.contains(prompt) else {
                return .error(.invalidParams("Unknown prompt: \(params?["name"]?.stringValue ?? "")"), id: id)
            }
            let arguments = params?["arguments"]
            return .result(prompt.message(app: arguments?["app"]?.stringValue, area: arguments?["area"]?.stringValue), id: id)
        case let method:
            return .error(.methodNotFound(method), id: id)
        }
    }

    private func callTool(_ params: JSONValue?, from session: MCPClientSession, id: JSONValue) async -> JSONRPCResponse {
        guard let name = params?["name"]?.stringValue else { return .error(.invalidParams("tools/call needs a tool name."), id: id) }
        guard let tool = toolbox.tool(named: name) else { return .error(.invalidParams("Unknown tool: \(name)"), id: id) }
        let rawArguments = params?["arguments"] ?? .null
        guard rawArguments.isNull || rawArguments.objectValue != nil else {
            return .error(.invalidParams("tools/call arguments must be an object."), id: id)
        }
        let arguments = MCPToolArguments(rawArguments.objectValue ?? [:])
        noteWorking(client: session.displayName)
        let outcome = await outcome(of: tool, arguments: arguments, from: session)
        for line in outcome.logLines {
            record(client: session.displayName, tool: name, target: line.target, outcome: line.outcome, reason: line.reason)
        }
        return .result(outcome.callResult, id: id)
    }

    private func outcome(of tool: any MCPTool, arguments: MCPToolArguments, from session: MCPClientSession) async -> MCPToolOutcome {
        let target = await logTarget(for: arguments)
        if let kind = tool.definition.proposalKind, !allows(kind) { return .failed(kind.refusal, target: target) }
        guard let workspace else { return .failed(MCPToolError.notConnected.localizedDescription, target: target) }
        do {
            let context = MCPToolContext(
                workspace: workspace,
                clientName: session.displayName,
                allowedProposals: allowedProposals,
                editsDrafts: editsDrafts,
                port: port
            )
            return try await tool.call(arguments, in: context)
        } catch {
            return .failed(error.localizedDescription, target: target)
        }
    }

    /// The app a call was about, by name when it's known, for log lines of
    /// calls that didn't run.
    private func logTarget(for arguments: MCPToolArguments) async -> String {
        guard let appID = try? arguments.optionalString("appId") else { return "" }
        return await (try? workspace?.app(matching: appID))?.name ?? appID
    }

    private func received(notification message: JSONRPCMessage, from session: MCPClientSession) {
        if message.method == "notifications/roots/list_changed" { requestRoots(of: session) }
    }

    /// A client's answer to `roots/list`: its project folder.
    private func received(response message: JSONRPCMessage, from session: MCPClientSession) {
        guard let requestID = message.id?.stringValue, pendingRootRequests.removeValue(forKey: requestID) == session.id else { return }
        let uri = message.result?["roots"]?.arrayValue?.first?["uri"]?.stringValue
        guard let index = sessions.firstIndex(where: { $0.id == session.id }), let uri else { return }
        let directory = MCPClientSession.displayPath(forRootURI: uri, homeDirectory: homeDirectory)
        sessions[index].workingDirectory = directory
        noteSeen(session.pairedClientID, at: now(), workingDirectory: directory)
        if pendingPairing?.connectedClient?.id == session.pairedClientID {
            pendingPairing?.connectedClient?.workingDirectory = directory
        }
    }

    // MARK: - GET and DELETE

    private func openStream(_ request: HTTPRequest, from clientID: MCPPairedClient.ID) -> HTTPReply {
        guard request.header("accept")?.contains("text/event-stream") == true else { return .response(.text(406)) }
        guard let sessionID = request.header("mcp-session-id") else { return .response(.text(400, "Missing Mcp-Session-Id header.")) }
        guard let index = sessions.firstIndex(where: { $0.id == sessionID && $0.pairedClientID == clientID }) else { return .response(.text(404)) }
        // One stream per session: a new one replaces the old.
        streams.removeValue(forKey: sessionID)?.continuation.finish()
        let (events, continuation) = AsyncStream<String>.makeStream()
        let streamToken = UUID()
        streams[sessionID] = (streamToken, continuation)
        sessions[index].hasOpenStream = true
        sessions[index].lastActivity = now()
        requestRoots(of: sessions[index])
        return .events(HTTPEventStream(headers: ["Mcp-Session-Id": sessionID], events: events) { [weak self] in
            Task { @MainActor in self?.streamDidClose(sessionID: sessionID, token: streamToken) }
        })
    }

    private func delete(_ request: HTTPRequest, from clientID: MCPPairedClient.ID) -> HTTPResponse {
        guard let sessionID = request.header("mcp-session-id"),
              sessions.contains(where: { $0.id == sessionID && $0.pairedClientID == clientID }) else { return .text(404) }
        disconnect(sessionID)
        return HTTPResponse(status: 200)
    }

    private func streamDidClose(sessionID: String, token streamToken: UUID) {
        guard streams[sessionID]?.token == streamToken else { return }
        streams[sessionID] = nil
        if let index = sessions.firstIndex(where: { $0.id == sessionID }) {
            sessions[index].hasOpenStream = false
            sessions[index].lastActivity = now()
            noteSeen(sessions[index].pairedClientID, at: now())
        }
    }

    /// Asks a client with roots for its project folder, over its stream.
    private func requestRoots(of session: MCPClientSession) {
        guard session.supportsRoots, let stream = streams[session.id] else { return }
        let requestID = "roots-\(UUID().uuidString)"
        pendingRootRequests[requestID] = session.id
        let message: JSONValue = ["jsonrpc": "2.0", "id": .string(requestID), "method": "roots/list"]
        stream.continuation.yield(HTTPEventStream.message(message.jsonString()))
    }

    /// One line per burst of rejected requests, not one per retry.
    private func recordUnauthorized() {
        let reason = String(localized: "Wrong or missing access token. Pair the assistant again in Settings → AI Assistants.")
        if let last = log.first, last.reason == reason, now().timeIntervalSince(last.date) < 60 { return }
        record(client: String(localized: "Unknown client"), tool: "—", target: "", outcome: .refused, reason: reason)
    }

    // MARK: - Checks

    /// Browsers send `Origin`; only pages served from this Mac may call.
    nonisolated static func isLocal(origin: String?) -> Bool {
        guard let origin, origin != "null" else { return origin == nil }
        guard let host = URLComponents(string: origin)?.host else { return false }
        return isLoopback(host)
    }

    /// Guards against DNS rebinding: the `Host` must name the loopback.
    nonisolated static func isLocal(host: String?) -> Bool {
        guard let host else { return true }
        guard let name = URLComponents(string: "http://\(host)")?.host else { return false }
        return isLoopback(name)
    }

    private nonisolated static func isLoopback(_ host: String) -> Bool {
        ["127.0.0.1", "localhost", "::1", "[::1]"].contains(host.lowercased())
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
