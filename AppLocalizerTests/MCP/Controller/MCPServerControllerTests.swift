//
//  MCPServerControllerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("MCPServerController")
struct MCPServerControllerTests {
    @Test func isOffUntilThePersonTurnsItOn() {
        let server = FakeLocalHTTPServer()
        let controller = MCPTestFixtures.controller(server: server)
        controller.startIfEnabled()
        #expect(!controller.isEnabled)
        #expect(controller.status == .off)
        #expect(controller.statusText == "Off")
        #expect(server.startedPorts.isEmpty)
        #expect(controller.allowedProposals == Set(MCPProposalKind.allCases))
    }

    @Test func turningItOnListensOnTheLoopback() async {
        let server = FakeLocalHTTPServer()
        let controller = MCPTestFixtures.controller(server: server)
        controller.setEnabled(true)
        await MCPTestFixtures.waitUntil { controller.isRunning }
        #expect(server.startedPorts == [MCPEndpoint.defaultPort])
        #expect(controller.status == .listening(port: MCPEndpoint.defaultPort))
        #expect(controller.url == "http://127.0.0.1:47321/mcp")
        #expect(controller.statusText == "Running · no assistant connected · 127.0.0.1:47321")
    }

    @Test func statusCountsConnectedAssistants() async throws {
        let clock = TestClock()
        let controller = MCPTestFixtures.controller(clock: clock)
        controller.setEnabled(true)
        await MCPTestFixtures.waitUntil { controller.isRunning }
        let (_, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        _ = try await MCPTestFixtures.initialize(controller, token: token)
        #expect(controller.statusText == "Running · 1 assistant connected · 127.0.0.1:47321")
        #expect(controller.connectedClients.map(\.name) == ["Claude Code"])
    }

    @Test func aPortInUseIsReported() async {
        let server = FakeLocalHTTPServer()
        server.failure = "Address already in use"
        let controller = MCPTestFixtures.controller(server: server)
        controller.setEnabled(true)
        await MCPTestFixtures.waitUntil { controller.status != .starting }
        #expect(controller.status == .failed(message: "Address already in use"))
        #expect(controller.statusText == "Couldn’t start: Address already in use")
    }

    @Test func turningItOffEndsSessionsAndThePairing() async throws {
        let server = FakeLocalHTTPServer()
        let clock = TestClock()
        let controller = MCPTestFixtures.controller(server: server, clock: clock)
        controller.setEnabled(true)
        await MCPTestFixtures.waitUntil { controller.isRunning }
        let (_, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        _ = try await MCPTestFixtures.initialize(controller, token: token)
        controller.beginPairing()

        controller.setEnabled(false)

        #expect(server.stopCount == 1)
        #expect(controller.status == .off)
        #expect(controller.sessions.isEmpty)
        #expect(controller.pendingPairing == nil)
        #expect(controller.pairedClients.count == 1)
    }

    @Test func theSwitchAndPermissionsSurviveARelaunch() async {
        let defaults = MCPTestFixtures.defaults()
        let controller = MCPTestFixtures.controller(defaults: defaults)
        controller.setEnabled(true)
        controller.setAllowed(.prices, false)

        let server = FakeLocalHTTPServer()
        let relaunched = MCPTestFixtures.controller(server: server, defaults: defaults)
        #expect(relaunched.isEnabled)
        #expect(!relaunched.allows(.prices))
        #expect(relaunched.allows(.storeText))
        relaunched.startIfEnabled()
        await MCPTestFixtures.waitUntil { relaunched.isRunning }
        #expect(server.startedPorts == [MCPEndpoint.defaultPort])
    }

    @Test func theLogKeepsTheNewestLinesFirst() {
        let clock = TestClock()
        let controller = MCPTestFixtures.controller(clock: clock)
        for index in 0..<(MCPServerController.logLimit + 5) {
            clock.advance(by: 1)
            controller.record(client: "Claude Code", tool: "list_apps", target: "call \(index)", outcome: .read)
        }
        #expect(controller.log.count == MCPServerController.logLimit)
        #expect(controller.log.first?.target == "call \(MCPServerController.logLimit + 4)")
        #expect(controller.log.first?.date == clock.now)
        controller.clearLog()
        #expect(controller.log.isEmpty)
    }

    @Test func aLogLineCanCarryItsOwnTime() {
        let clock = TestClock()
        let controller = MCPTestFixtures.controller(clock: clock)
        let earlier = clock.now.addingTimeInterval(-600)
        controller.record(client: "Claude Code", tool: "list_apps", target: "Northpier Studio", outcome: .read, at: earlier)
        #expect(controller.log.first?.date == earlier)
    }

    @Test func promptsAreOfferedOnlyWithTheirTools() {
        #expect(MCPTestFixtures.controller(toolbox: MCPToolbox(tools: [FakeMCPTool(name: "list_apps")])).availablePrompts.isEmpty)
        #expect(MCPTestFixtures.controller().availablePrompts == [
            .translateMissing, .fillPrivacyFromCode, .fillAgeRating, .whatsNewFromGit,
            .translateCaptions, .shortenOverflowingCaptions, .reviseTemplate,
        ])
    }

    @Test func quietSessionsWithoutAStreamAreForgotten() async throws {
        let clock = TestClock()
        let controller = MCPTestFixtures.controller(clock: clock)
        let (client, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        _ = try await MCPTestFixtures.initialize(controller, token: token)
        clock.advance(by: MCPServerController.idleTimeout - 1)
        controller.pruneIdleSessions()
        #expect(controller.sessions.count == 1)
        clock.advance(by: 2)
        controller.pruneIdleSessions()
        #expect(controller.sessions.isEmpty)
        #expect(try controller.status(of: #require(controller.pairedClients.first { $0.id == client.id })).isConnected == false)
    }

    @Test func toolCallsShowTheAssistantWorking() async throws {
        let clock = TestClock()
        let controller = MCPTestFixtures.controller(clock: clock)
        let (_, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        let session = try await MCPTestFixtures.initialize(controller, token: token)
        #expect(!controller.isWorking)
        _ = try await MCPTestFixtures.call(controller, "tools/call", params: ["name": "list_apps"], token: token, session: session)
        #expect(controller.isWorking)
        #expect(controller.workingClient == "Claude Code")
    }

    @Test func workingStopsAfterTheInterval() async {
        let controller = MCPTestFixtures.controller()
        controller.noteWorking(client: "Cursor", for: .milliseconds(10))
        #expect(controller.isWorking)
        #expect(controller.workingClient == "Cursor")
        await MCPTestFixtures.waitUntil { !controller.isWorking }
        #expect(!controller.isWorking)
    }
}
