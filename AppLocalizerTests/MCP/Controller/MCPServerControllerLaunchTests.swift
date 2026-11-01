//
//  MCPServerControllerLaunchTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The runs AppLocalizer starts: they act as the paired Claude Code with a
/// token each that works only while they run.
@MainActor
@Suite("MCP · runs AppLocalizer starts")
struct MCPServerControllerLaunchTests {
    private let clock = TestClock()
    private let server = FakeLocalHTTPServer()
    private let secrets = InMemorySecretStore()
    private let controller: MCPServerController

    init() {
        controller = MCPTestFixtures.controller(server: server, secrets: secrets, clock: clock)
    }

    @Test func runsActAsTheClaudeCodePairedLast() {
        MCPTestFixtures.pair(.claudeCode, in: controller, at: clock.now)
        let latest = MCPTestFixtures.pair(.claudeCode, in: controller, at: clock.now).client
        MCPTestFixtures.pair(.cursor, in: controller, at: clock.now)
        #expect(controller.launchClientID() == latest.id)
        #expect(controller.pairedClients.count == 3)
    }

    @Test func withoutOneItPairsClaudeCode() throws {
        MCPTestFixtures.pair(.cursor, in: controller, at: clock.now)
        let id = try #require(controller.launchClientID())
        let client = try #require(controller.pairedClients.first { $0.id == id })
        #expect(client.kind == .claudeCode)
        #expect(client.name == "Claude Code")
        #expect(client.pairedAt == clock.now)
        #expect(try secrets.secret(named: client.secretName) == controller.tokens[id])
        #expect(controller.launchClientID() == id)
    }

    @Test func aRunTokenConnectsAsItsClientUntilRevoked() async throws {
        let clientID = try #require(controller.launchClientID())
        let token = controller.issueRunToken(for: clientID)
        #expect(token.hasPrefix(MCPAccessToken.prefix))
        #expect(token != controller.tokens[clientID])

        _ = try await MCPTestFixtures.initialize(controller, token: token)
        #expect(controller.sessions.map(\.pairedClientID) == [clientID])
        #expect(controller.pairedClients.first?.lastSeenAt == clock.now)

        controller.revokeRunToken(token)
        let response = try #require(await controller.handle(MCPTestFixtures.request(token: token, body: MCPTestFixtures.rpc("ping"))).response)
        #expect(response.status == 401)
        // The pairing's own token still works.
        #expect(controller.authorizedClientID(for: "Bearer \(controller.tokens[clientID] ?? "")") == clientID)
    }

    @Test func aRunTokenWhoseClientIsGoneIsRefused() throws {
        let clientID = try #require(controller.launchClientID())
        let token = controller.issueRunToken(for: clientID)
        controller.restorePairings([], tokens: [:])
        #expect(controller.authorizedClientID(for: "Bearer \(token)") == nil)
    }

    @Test func startForLaunchTurnsTheServerOn() async {
        #expect(!controller.isEnabled)
        #expect(await controller.startForLaunch() == nil)
        #expect(controller.isEnabled)
        #expect(controller.isRunning)
        #expect(server.startedPorts == [controller.port])
    }

    @Test func startForLaunchSaysWhyItCouldnt() async {
        server.failure = "Port 47321 is in use."
        #expect(await controller.startForLaunch() == "Port 47321 is in use.")
        #expect(!controller.isRunning)
    }

    @Test func withTheHelperReadyClaudeCodeCountsAsConnected() async {
        #expect(controller.assistantStatus == .notSetUp)
        #expect(controller.assistantClient == nil)

        let launcher = ClaudeCodeTestFixtures.launcher(assistants: controller, clock: clock)
        await launcher.refreshHelper()
        #expect(controller.assistantStatus == .connected(client: "Claude Code"))
        // A stand-in until the first run pairs it.
        #expect(controller.assistantClient?.id == MCPServerController.launchStandInID)
        #expect(controller.assistantClient?.kind == .claudeCode)

        let cursor = MCPTestFixtures.pair(.cursor, in: controller, at: clock.now).client
        #expect(controller.leadingClient?.id == cursor.id)
        let claudeCode = MCPTestFixtures.pair(.claudeCode, in: controller, at: clock.now).client
        MCPTestFixtures.pair(.cursor, in: controller, at: clock.now)
        #expect(controller.assistantClient?.id == claudeCode.id)
    }
}
