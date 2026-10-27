//
//  MCPBridgeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing

@Suite("MCPBridge")
struct MCPBridgeTests {
    private static let initialize = #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}"#
    private static let initialized = #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#
    private static let listTools = #"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#
    private static let initializeResult = #"{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-06-18","serverInfo":{"name":"AppLocalizer"}}}"#
    private static let toolsResult = #"{"jsonrpc":"2.0","id":2,"result":{"tools":[]}}"#

    private static func session(_ id: String, body: String = initializeResult) -> FakeBridgeTransport.Reply {
        .init(headers: ["Content-Type": "application/json", "Mcp-Session-Id": id], body: body)
    }

    private static let accepted = FakeBridgeTransport.Reply(status: 202, headers: [:])

    private func bridge(_ transport: FakeBridgeTransport, log: @escaping @Sendable (String) -> Void = { _ in }) -> MCPBridge {
        MCPBridge(options: MCPBridgeOptions(token: "al_tok"), transport: transport, log: log)
    }

    @Test func messagesArePostedWithTheTokenAndTheSession() async {
        let transport = FakeBridgeTransport([.success(Self.session("s1")), .success(Self.accepted), .success(.init(body: Self.toolsResult))])
        let bridge = bridge(transport)

        #expect(await bridge.forward(Self.initialize) == [Self.initializeResult])
        #expect(await bridge.forward(Self.initialized).isEmpty)
        #expect(await bridge.forward(Self.listTools) == [Self.toolsResult])

        let requests = await transport.requests
        #expect(requests.map(\.url) == Array(repeating: MCPBridgeOptions.defaultURL, count: 3))
        #expect(requests.allSatisfy { $0.httpMethod == "POST" && $0.value(forHTTPHeaderField: "Authorization") == "Bearer al_tok" })
        #expect(requests[0].value(forHTTPHeaderField: "Mcp-Session-Id") == nil)
        #expect(requests[0].value(forHTTPHeaderField: "Accept") == "application/json, text/event-stream")
        #expect(requests[2].value(forHTTPHeaderField: "Mcp-Session-Id") == "s1")
        #expect(requests[2].value(forHTTPHeaderField: "MCP-Protocol-Version") == "2025-06-18")
        #expect(await transport.bodies == [Self.initialize, Self.initialized, Self.listTools])
    }

    @Test func aForgottenSessionIsStartedAgainAndTheMessageRetried() async {
        let transport = FakeBridgeTransport([
            .success(Self.session("s1")),
            .success(.init(status: 404, headers: ["Content-Type": "text/plain"], body: "Unknown session; initialize again.")),
            .success(Self.session("s2")),
            .success(Self.accepted),
            .success(.init(body: Self.toolsResult)),
        ])
        let lines = LogLines()
        let bridge = bridge(transport) { lines.append($0) }
        _ = await bridge.forward(Self.initialize)

        #expect(await bridge.forward(Self.listTools) == [Self.toolsResult])
        #expect(await bridge.sessionID == "s2")
        #expect(await transport.bodies == [Self.initialize, Self.listTools, Self.initialize, Self.initialized, Self.listTools])
        #expect(await transport.requests.last?.value(forHTTPHeaderField: "Mcp-Session-Id") == "s2")
        #expect(lines.all == ["AppLocalizer forgot the session; starting a new one."])
    }

    @Test func anUnreachableAppAnswersRequestsOnly() async throws {
        let transport = FakeBridgeTransport([.failure(URLError(.cannotConnectToHost)), .failure(URLError(.cannotConnectToHost))])
        let lines = LogLines()
        let bridge = bridge(transport) { lines.append($0) }

        let reply = try #require(await bridge.forward(#"{"jsonrpc":"2.0","id":"a1","method":"tools/list"}"#).first)
        #expect(reply == MCPBridgeMessage.error(id: #""a1""#, code: MCPBridge.failureCode, message: MCPBridge.unreachable))
        #expect(await bridge.forward(Self.initialized).isEmpty)
        #expect(lines.all.count == 2)
    }

    @Test func aRefusedTokenSaysToPairAgain() async throws {
        let transport = FakeBridgeTransport([.success(.init(status: 401, headers: ["Content-Type": "text/plain"], body: "Wrong or missing access token."))])
        let reply = try #require(await bridge(transport).forward(Self.initialize).first)
        let error = try #require(Self.object(reply)["error"] as? [String: Any])
        #expect(Self.object(reply)["id"] as? Int == 1)
        #expect((error["message"] as? String)?.contains("Pair the assistant again") == true)
    }

    @Test func appLocalizersOwnErrorsPassThrough() async {
        let refusal = #"{"jsonrpc":"2.0","id":2,"error":{"code":-32601,"message":"Method not found"}}"#
        let transport = FakeBridgeTransport([.success(.init(status: 400, body: refusal))])
        #expect(await bridge(transport).forward(Self.listTools) == [refusal])
    }

    @Test func aLineThatIsntJSONIsAParseError() async throws {
        let transport = FakeBridgeTransport([])
        let reply = try #require(await bridge(transport).forward("hello").first)
        #expect(Self.object(reply)["id"] is NSNull)
        #expect((Self.object(reply)["error"] as? [String: Any])?["code"] as? Int == -32700)
        #expect(await transport.requests.isEmpty)
    }

    @Test func eventStreamRepliesBecomeOneLineEach() async {
        let stream = "event: message\ndata: {\"jsonrpc\":\"2.0\",\"method\":\"notifications/progress\"}\n\ndata: \(Self.toolsResult)\n\n"
        let transport = FakeBridgeTransport([.success(.init(headers: ["Content-Type": "text/event-stream"], body: stream))])
        #expect(await bridge(transport).forward(Self.listTools) == [#"{"jsonrpc":"2.0","method":"notifications/progress"}"#, Self.toolsResult])
    }

    @Test func prettyPrintedRepliesAreCompacted() async throws {
        let transport = FakeBridgeTransport([.success(.init(body: "{\n  \"jsonrpc\" : \"2.0\",\n  \"id\" : 2\n}"))])
        let reply = try #require(await bridge(transport).forward(Self.listTools).first)
        #expect(!reply.contains("\n"))
        #expect(Self.object(reply)["id"] as? Int == 2)
    }

    @Test func closingEndsTheSession() async {
        let transport = FakeBridgeTransport([.success(Self.session("s1")), .success(.init(status: 204, headers: [:]))])
        let bridge = bridge(transport)
        await bridge.close()
        #expect(await transport.requests.isEmpty)

        _ = await bridge.forward(Self.initialize)
        await bridge.close()
        let delete = await transport.requests.last
        #expect(delete?.httpMethod == "DELETE")
        #expect(delete?.value(forHTTPHeaderField: "Mcp-Session-Id") == "s1")
        #expect(await bridge.sessionID == nil)
    }

    private static func object(_ line: String) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]) ?? [:]
    }
}
