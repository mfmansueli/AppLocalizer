//
//  MCPTestFixtures.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Controllers, workspaces and requests for the MCP server tests.
@MainActor
enum MCPTestFixtures {
    static let homeDirectory = "/Users/sam"
    static let bridgePath = "/Applications/AppLocalizer.app/Contents/MacOS/applocalizer-mcp"

    static let apps = [
        StoreApp(id: "6450000001", name: "Lumen Journal", bundleID: "com.northpier.lumen", sku: "LUMEN-01", primaryLocale: "en-US"),
        StoreApp(id: "6450000003", name: "Tempo Metronome", bundleID: "com.northpier.tempo", sku: "TEMPO", primaryLocale: "en-US"),
        StoreApp(id: "6450000004", name: "Fieldnote", bundleID: "com.northpier.fieldnote", primaryLocale: "de-DE"),
        StoreApp(id: "6450000005", name: "Field Guide", bundleID: "com.northpier.guide", primaryLocale: "en-GB"),
    ]

    static func controller(
        server: FakeLocalHTTPServer = FakeLocalHTTPServer(),
        secrets: InMemorySecretStore = InMemorySecretStore(),
        defaults: UserDefaults? = nil,
        clock: TestClock = TestClock(),
        toolbox: MCPToolbox = .standard
    ) -> MCPServerController {
        MCPServerController(
            server: server,
            secrets: secrets,
            defaults: defaults,
            toolbox: toolbox,
            homeDirectory: homeDirectory,
            bridgePath: bridgePath,
            now: { clock.now }
        )
    }

    /// Pairs a client in memory and returns its token.
    @discardableResult
    static func pair(_ kind: MCPClientKind = .claudeCode, in controller: MCPServerController, at date: Date) -> (client: MCPPairedClient, token: String) {
        let client = MCPPairedClient(id: UUID(), kind: kind, name: kind.title, pairedAt: date)
        let token = MCPAccessToken.generate()
        controller.restorePairings(controller.pairedClients + [client], tokens: controller.tokens.merging([client.id: token]) { $1 })
        return (client, token)
    }

    static func workspace(
        apps: [StoreApp] = apps,
        changes: ChangeQueue = ChangeQueue(),
        pricingModes: PricingModeStore? = nil,
        storePage: (any StorePageServices)? = nil,
        appInformation: (any AppInformationServices)? = nil,
        glossary: TranslationGlossary = TranslationGlossary(),
        commission: Commission = .smallBusiness
    ) -> MCPWorkspace {
        var services = WorkspaceServices.debug
        if let storePage { services.storePage = storePage }
        if let appInformation { services.appInformation = appInformation }
        return MCPWorkspace(
            teamName: "Northpier Studio",
            services: services,
            changes: changes,
            pricingModes: pricingModes ?? PricingModeStore(defaults: nil),
            apps: { apps },
            glossary: { glossary },
            commission: { commission }
        )
    }

    /// A fresh `UserDefaults` suite, emptied.
    static func defaults() -> UserDefaults {
        let name = "MCPTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    // MARK: - Requests

    static func request(
        _ method: String = "POST",
        path: String = MCPEndpoint.path,
        token: String?,
        session: String? = nil,
        body: JSONValue? = nil,
        headers: [String: String] = [:]
    ) -> HTTPRequest {
        var allHeaders = ["Host": "127.0.0.1:47321", "Accept": "application/json, text/event-stream"]
        if let token { allHeaders["Authorization"] = "Bearer \(token)" }
        if let session { allHeaders["Mcp-Session-Id"] = session }
        allHeaders.merge(headers) { $1 }
        return HTTPRequest(method: method, target: path, headers: allHeaders, body: body.map { Data($0.jsonString().utf8) } ?? Data())
    }

    static func rpc(_ method: String, id: Int? = 1, params: JSONValue? = nil) -> JSONValue {
        var message: [String: JSONValue] = ["jsonrpc": "2.0", "method": .string(method)]
        if let id { message["id"] = .int(id) }
        if let params { message["params"] = params }
        return .object(message)
    }

    static func initializeParams(
        clientName: String = "claude-code",
        title: String? = nil,
        version: String = MCPProtocolVersion.latest,
        roots: Bool = false
    ) -> JSONValue {
        var info: [String: JSONValue] = ["name": .string(clientName), "version": "2.1.0"]
        if let title { info["title"] = .string(title) }
        let capabilities: JSONValue = roots ? ["roots": ["listChanged": true]] : [:]
        return ["protocolVersion": .string(version), "capabilities": capabilities, "clientInfo": .object(info)]
    }

    /// Sends `initialize` with `token` and returns the new session's ID.
    static func initialize(
        _ controller: MCPServerController,
        token: String,
        clientName: String = "claude-code",
        title: String? = nil,
        roots: Bool = false
    ) async throws -> String {
        let params = initializeParams(clientName: clientName, title: title, roots: roots)
        let response = try #require(await controller.handle(request(token: token, body: rpc("initialize", params: params))).response)
        #expect(response.status == 200)
        return try #require(response.headers["Mcp-Session-Id"])
    }

    /// Sends one JSON-RPC request in `session` and returns the response's
    /// JSON.
    static func call(
        _ controller: MCPServerController,
        _ method: String,
        params: JSONValue? = nil,
        token: String,
        session: String
    ) async throws -> JSONValue {
        let response = try #require(await controller.handle(request(token: token, session: session, body: rpc(method, params: params))).response)
        #expect(response.status == 200)
        return try json(response)
    }

    static func json(_ response: HTTPResponse) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: response.body)
    }

    /// The text of a `tools/call` result.
    static func toolText(_ message: JSONValue) -> String? {
        message["result"]?["content"]?.arrayValue?.first?["text"]?.stringValue
    }

    /// Waits for main-actor work the controller started (server events) to
    /// land.
    static func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}
