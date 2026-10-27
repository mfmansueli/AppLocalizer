//
//  MCPServerControllerHTTPTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Requests to `/mcp`: the local-only checks, per-client tokens, sessions
/// and the JSON-RPC methods.
@MainActor
@Suite("MCP server requests")
struct MCPServerControllerHTTPTests {
    private let clock = TestClock()
    private let controller: MCPServerController
    private let client: MCPPairedClient
    private let token: String

    init() {
        controller = MCPTestFixtures.controller(clock: clock)
        (client, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
    }

    private func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        try #require(await controller.handle(request).response)
    }

    // MARK: - Checks

    @Test func otherPathsAreNotFound() async throws {
        #expect(try await send(MCPTestFixtures.request(path: "/other", token: token)).status == 404)
    }

    @Test func onlyThisMacMayConnect() async throws {
        let website = MCPTestFixtures.request(token: token, body: MCPTestFixtures.rpc("ping"), headers: ["Origin": "https://evil.example"])
        #expect(try await send(website).status == 403)
        let rebound = MCPTestFixtures.request(token: token, body: MCPTestFixtures.rpc("ping"), headers: ["Host": "evil.example:47321"])
        #expect(try await send(rebound).status == 403)

        #expect(MCPServerController.isLocal(origin: nil))
        #expect(MCPServerController.isLocal(origin: "http://localhost:3000"))
        #expect(MCPServerController.isLocal(origin: "http://[::1]:47321"))
        #expect(!MCPServerController.isLocal(origin: "null"))
        #expect(MCPServerController.isLocal(host: nil))
        #expect(MCPServerController.isLocal(host: "127.0.0.1:47321"))
        #expect(MCPServerController.isLocal(host: "LOCALHOST"))
        #expect(!MCPServerController.isLocal(host: "127.0.0.1.example.com"))
    }

    @Test func requestsWithoutAPairedTokenAreRefusedAndLoggedOnce() async throws {
        let missing = try await send(MCPTestFixtures.request(token: nil, body: MCPTestFixtures.rpc("ping")))
        #expect(missing.status == 401)
        #expect(missing.headers["WWW-Authenticate"] == "Bearer")
        let wrong = try await send(MCPTestFixtures.request(token: MCPAccessToken.generate(), body: MCPTestFixtures.rpc("ping")))
        #expect(wrong.status == 401)
        #expect(controller.log.count == 1)
        #expect(controller.log.first?.outcome == .refused)

        clock.advance(by: 61)
        _ = try await send(MCPTestFixtures.request(token: nil, body: MCPTestFixtures.rpc("ping")))
        #expect(controller.log.count == 2)
    }

    // MARK: - Sessions

    @Test func initializeOpensASessionForThePairedClient() async throws {
        let params = MCPTestFixtures.initializeParams(version: "2025-06-18", roots: true)
        let response = try await send(MCPTestFixtures.request(token: token, body: MCPTestFixtures.rpc("initialize", params: params)))
        let json = try MCPTestFixtures.json(response)
        let sessionID = try #require(response.headers["Mcp-Session-Id"])

        #expect(json["result"]?["protocolVersion"] == "2025-06-18")
        #expect(json["result"]?["serverInfo"]?["name"] == "applocalizer")
        #expect(json["result"]?["capabilities"]?["tools"] != nil)
        let session = try #require(controller.sessions.first)
        #expect(session.id == sessionID)
        #expect(session.pairedClientID == client.id)
        #expect(session.displayName == "Claude Code")
        #expect(session.clientVersion == "2.1.0")
        #expect(session.supportsRoots)
        #expect(controller.pairedClients.first?.lastSeenAt == clock.now)
        #expect(controller.status(of: client) == .connected(lastCall: clock.now))
        #expect(controller.log.first?.tool == "initialize")
    }

    @Test func anUnknownProtocolVersionGetsTheLatest() async throws {
        let params = MCPTestFixtures.initializeParams(version: "1999-01-01")
        let json = try await MCPTestFixtures.json(send(MCPTestFixtures.request(token: token, body: MCPTestFixtures.rpc("initialize", params: params))))
        #expect(json["result"]?["protocolVersion"] == .string(MCPProtocolVersion.latest))
    }

    @Test func requestsNeedTheirClientsOwnSession() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let (_, otherToken) = MCPTestFixtures.pair(.cursor, in: controller, at: clock.now)

        let noSession = try await send(MCPTestFixtures.request(token: token, body: MCPTestFixtures.rpc("ping")))
        #expect(noSession.status == 400)
        let unknown = try await send(MCPTestFixtures.request(token: token, session: "nope", body: MCPTestFixtures.rpc("ping")))
        #expect(unknown.status == 404)
        let borrowed = try await send(MCPTestFixtures.request(token: otherToken, session: session, body: MCPTestFixtures.rpc("ping")))
        #expect(borrowed.status == 404)
        let unsupported = MCPTestFixtures.request(
            token: token, session: session, body: MCPTestFixtures.rpc("ping"), headers: ["MCP-Protocol-Version": "1999-01-01"]
        )
        #expect(try await send(unsupported).status == 400)
    }

    @Test func deleteEndsTheSession() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        clock.advance(by: 30)
        let response = try await send(MCPTestFixtures.request("DELETE", token: token, session: session))
        #expect(response.status == 200)
        #expect(controller.sessions.isEmpty)
        #expect(try controller.status(of: #require(controller.pairedClients.first)) == .disconnected(lastSeen: clock.now.addingTimeInterval(-30)))
        #expect(try await send(MCPTestFixtures.request("DELETE", token: token, session: session)).status == 404)
    }

    @Test func otherMethodsAreNotAllowed() async throws {
        let response = try await send(MCPTestFixtures.request("PUT", token: token))
        #expect(response.status == 405)
        #expect(response.headers["Allow"] == "GET, POST, DELETE")
    }

    // MARK: - JSON-RPC

    @Test func unreadableBodiesAreParseErrors() async throws {
        var request = MCPTestFixtures.request(token: token)
        request.body = Data("{".utf8)
        let response = try await send(request)
        #expect(response.status == 400)
        #expect(try MCPTestFixtures.json(response)["error"]?["code"] == -32700)

        request.body = Data(#"[{"jsonrpc":"2.0","id":1,"method":"ping"}]"#.utf8)
        let batch = try await send(request)
        #expect(batch.status == 400)
        #expect(try MCPTestFixtures.json(batch)["error"]?["code"] == -32600)
    }

    @Test func notificationsAreAccepted() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let notification = MCPTestFixtures.rpc("notifications/initialized", id: nil)
        #expect(try await send(MCPTestFixtures.request(token: token, session: session, body: notification)).status == 202)
    }

    @Test func pingAndUnknownMethods() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let ping = try await MCPTestFixtures.call(controller, "ping", token: token, session: session)
        #expect(ping == ["jsonrpc": "2.0", "id": 1, "result": [:]])
        let unknown = try await MCPTestFixtures.call(controller, "resources/list", token: token, session: session)
        #expect(unknown["error"]?["code"] == -32601)
    }

    @Test func toolsListDescribesEachTool() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let json = try await MCPTestFixtures.call(controller, "tools/list", token: token, session: session)
        let tools = try #require(json["result"]?["tools"]?.arrayValue)
        #expect(tools.compactMap { $0["name"]?.stringValue } == MCPToolbox.standard.tools.map(\.definition.name))
        #expect(tools.first?["annotations"]?["readOnlyHint"] == true)
        let propose = tools.first { $0["name"] == "propose_listing_text" }
        #expect(propose?["annotations"]?["readOnlyHint"] == false)
        #expect(tools.first?["inputSchema"]?["type"] == "object")
    }

    @Test func toolsNeedAConnectedAccount() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let json = try await MCPTestFixtures.call(controller, "tools/call", params: ["name": "list_apps"], token: token, session: session)
        #expect(json["result"]?["isError"] == true)
        #expect(MCPTestFixtures.toolText(json) == MCPToolError.notConnected.localizedDescription)
        #expect(controller.log.first?.outcome == .refused)
        #expect(controller.log.first?.tool == "list_apps")
    }

    @Test func toolsReadTheWorkspace() async throws {
        controller.workspace = MCPTestFixtures.workspace()
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let json = try await MCPTestFixtures.call(controller, "tools/call", params: ["name": "list_apps", "arguments": [:]], token: token, session: session)
        #expect(json["result"]?["isError"] == false)
        let text = try #require(MCPTestFixtures.toolText(json))
        let apps = try JSONDecoder().decode(JSONValue.self, from: Data(text.utf8))
        #expect(apps.arrayValue?.count == MCPTestFixtures.apps.count)
        #expect(controller.log.first?.outcome == .read)
        #expect(controller.log.first?.target == "Northpier Studio · 4 apps")
        #expect(controller.log.first?.client == "Claude Code")
    }

    @Test func badToolCallsAreInvalidParams() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let calls: [JSONValue] = [[:], ["name": "nope"], ["name": "list_apps", "arguments": [1]]]
        for params in calls {
            let json = try await MCPTestFixtures.call(controller, "tools/call", params: params, token: token, session: session)
            #expect(json["error"]?["code"] == -32602)
        }
    }

    @Test func proposalsFollowThePermissions() async throws {
        let tool = FakeMCPTool(name: "propose_prices", proposalKind: .prices)
        let controller = MCPTestFixtures.controller(clock: clock, toolbox: MCPToolbox(tools: [tool]))
        let (_, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        controller.workspace = MCPTestFixtures.workspace()
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let params: JSONValue = ["name": "propose_prices", "arguments": ["appId": "lumen"]]

        controller.setAllowed(.prices, false)
        let refused = try await MCPTestFixtures.call(controller, "tools/call", params: params, token: token, session: session)
        #expect(refused["result"]?["isError"] == true)
        #expect(MCPTestFixtures.toolText(refused) == MCPProposalKind.prices.refusal)
        #expect(tool.calls.isEmpty)
        #expect(controller.log.first?.target == "Lumen Journal")

        controller.setAllowed(.prices, true)
        let queued = try await MCPTestFixtures.call(controller, "tools/call", params: params, token: token, session: session)
        #expect(queued["result"]?["isError"] == false)
        #expect(tool.calls == [MCPToolArguments(["appId": "lumen"])])
        #expect(controller.log.first?.outcome == .proposed)
    }

    @Test func toolErrorsAreReturnedAsFailedCalls() async throws {
        let tool = FakeMCPTool(name: "get_listing")
        tool.error = MCPToolError.notFound("No app matches “Nope”.")
        let controller = MCPTestFixtures.controller(clock: clock, toolbox: MCPToolbox(tools: [tool]))
        let (_, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        controller.workspace = MCPTestFixtures.workspace()
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let params: JSONValue = ["name": "get_listing", "arguments": ["appId": "Nope"]]
        let json = try await MCPTestFixtures.call(controller, "tools/call", params: params, token: token, session: session)
        #expect(json["result"]?["isError"] == true)
        #expect(MCPTestFixtures.toolText(json) == "No app matches “Nope”.")
        #expect(controller.log.first?.reason == "No app matches “Nope”.")
    }

    @Test func promptsAreListedAndFilledIn() async throws {
        let names = ["list_apps", "get_age_rating", "propose_age_rating"]
        let controller = MCPTestFixtures.controller(clock: clock, toolbox: MCPToolbox(tools: names.map { FakeMCPTool(name: $0) }))
        let (_, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        let session = try await MCPTestFixtures.initialize(controller, token: token)

        let list = try await MCPTestFixtures.call(controller, "prompts/list", token: token, session: session)
        #expect(list["result"]?["prompts"]?.arrayValue?.map { $0["name"] } == ["fill_age_rating"])
        let params: JSONValue = ["name": "fill_age_rating", "arguments": ["app": "Lumen Journal"]]
        let prompt = try await MCPTestFixtures.call(controller, "prompts/get", params: params, token: token, session: session)
        let text = prompt["result"]?["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue
        #expect(text?.contains("the app “Lumen Journal”") == true)
        let unavailable = try await MCPTestFixtures.call(controller, "prompts/get", params: ["name": "translate_missing"], token: token, session: session)
        #expect(unavailable["error"]?["code"] == -32602)
    }

    // MARK: - Streams and roots

    @Test func streamsNeedToAcceptEvents() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let reply = await controller.handle(MCPTestFixtures.request("GET", token: token, session: session, headers: ["Accept": "application/json"]))
        #expect(reply.response?.status == 406)
        let noSession = await controller.handle(MCPTestFixtures.request("GET", token: token))
        #expect(noSession.response?.status == 400)
    }

    @Test func aStreamAsksForTheProjectFolder() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token, roots: true)
        let reply = await controller.handle(MCPTestFixtures.request("GET", token: token, session: session))
        let stream = try #require(reply.eventStream)
        #expect(stream.headers["Mcp-Session-Id"] == session)
        #expect(controller.sessions.first?.hasOpenStream == true)

        var events = stream.events.makeAsyncIterator()
        let event = try #require(await events.next())
        let payload = String(event.dropFirst("event: message\ndata: ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        let request = try JSONDecoder().decode(JSONValue.self, from: Data(payload.utf8))
        #expect(request["method"] == "roots/list")
        let requestID = try #require(request["id"])

        let answer: JSONValue = ["jsonrpc": "2.0", "id": requestID, "result": ["roots": [["uri": "file:///Users/sam/Developer/Lumen"]]]]
        #expect(try await send(MCPTestFixtures.request(token: token, session: session, body: answer)).status == 202)
        #expect(controller.sessions.first?.workingDirectory == "~/Developer/Lumen")
        #expect(controller.pairedClients.first?.workingDirectory == "~/Developer/Lumen")

        // An answer nobody asked for changes nothing.
        let stray: JSONValue = ["jsonrpc": "2.0", "id": "roots-x", "result": ["roots": [["uri": "file:///tmp"]]]]
        #expect(try await send(MCPTestFixtures.request(token: token, session: session, body: stray)).status == 202)
        #expect(controller.sessions.first?.workingDirectory == "~/Developer/Lumen")
    }

    @Test func closingAStreamKeepsTheSession() async throws {
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        let reply = await controller.handle(MCPTestFixtures.request("GET", token: token, session: session))
        let stream = try #require(reply.eventStream)
        stream.onClose()
        await MCPTestFixtures.waitUntil { controller.sessions.first?.hasOpenStream == false }
        #expect(controller.sessions.first?.hasOpenStream == false)
        #expect(controller.streams.isEmpty)
    }
}
