//
//  MCPServerControllerPairingTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Pairing an assistant with its own token or a code, and revoking it.
@MainActor
@Suite("MCP pairing")
struct MCPServerControllerPairingTests {
    private let clock = TestClock()
    private let secrets = InMemorySecretStore()
    private let defaults = MCPTestFixtures.defaults()
    private let controller: MCPServerController

    init() {
        controller = MCPTestFixtures.controller(secrets: secrets, defaults: defaults, clock: clock)
    }

    private func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        try #require(await controller.handle(request).response)
    }

    private func redeem(_ code: String) async throws -> HTTPResponse {
        try await send(MCPTestFixtures.request(path: MCPEndpoint.pairingPath, token: nil, body: ["code": .string(code)]))
    }

    @Test func pairingMakesATokenForOneClientAndACode() throws {
        controller.beginPairing()
        let pairing = try #require(controller.pendingPairing)
        #expect(pairing.kind == .claudeCode)
        #expect(pairing.token.hasPrefix(MCPAccessToken.prefix))
        #expect(pairing.code.expiresAt == clock.now.addingTimeInterval(MCPPairingCode.lifetime))
        #expect(!pairing.isWaiting)
        #expect(controller.pairingSnippet?.contains("Bearer \(pairing.token)") == true)
        #expect(controller.pairingSnippet?.contains(controller.url) == true)

        controller.markPairingCopied()
        #expect(controller.pendingPairing?.isWaiting == true)
        controller.choosePairingKind(.codex)
        #expect(controller.pendingPairing?.kind == .codex)
        #expect(controller.pendingPairing?.token == pairing.token)
        #expect(controller.pendingPairing?.isWaiting == false)
        #expect(controller.pairingSnippet?.contains(MCPTestFixtures.bridgePath) == true)
        #expect(controller.pairedClients.isEmpty)
    }

    @Test func theClientIsPairedWhenItFirstUsesItsToken() async throws {
        controller.beginPairing(kind: .cursor)
        let token = try #require(controller.pendingPairing?.token)

        _ = try await MCPTestFixtures.initialize(controller, token: token, clientName: "cursor-vscode")

        let client = try #require(controller.pairedClients.first)
        #expect(controller.pairedClients.count == 1)
        #expect(client.kind == .cursor)
        #expect(client.name == "Cursor")
        #expect(client.pairedAt == clock.now)
        #expect(try secrets.secret(named: client.secretName) == token)
        #expect(controller.pendingPairing?.connectedClient?.id == client.id)

        controller.finishPairing()
        #expect(controller.pendingPairing == nil)
        _ = try await MCPTestFixtures.initialize(controller, token: token, clientName: "cursor-vscode")
        #expect(controller.pairedClients.count == 1)
        #expect(controller.sessions.count == 2)
    }

    @Test func otherClientsAreNamedByWhatTheySend() async throws {
        controller.beginPairing(kind: .other)
        let token = try #require(controller.pendingPairing?.token)
        _ = try await MCPTestFixtures.initialize(controller, token: token, clientName: "zed", title: "Zed")
        #expect(controller.pairedClients.first?.name == "Zed")
        #expect(controller.pairedClients.first?.monogram == "ZE")
    }

    @Test func aCancelledPairingsTokenNeverWorks() async throws {
        controller.beginPairing()
        let token = try #require(controller.pendingPairing?.token)
        controller.cancelPairing()
        let initialize = MCPTestFixtures.rpc("initialize", params: MCPTestFixtures.initializeParams())
        let response = try await send(MCPTestFixtures.request(token: token, body: initialize))
        #expect(response.status == 401)
        #expect(controller.pairedClients.isEmpty)
    }

    @Test func aPairingCodeIsTradedForTheTokenOnce() async throws {
        controller.beginPairing()
        let pairing = try #require(controller.pendingPairing)

        let response = try await redeem(pairing.code.formatted)
        #expect(response.status == 200)
        let json = try MCPTestFixtures.json(response)
        #expect(json["token"] == .string(pairing.token))
        #expect(json["url"] == .string(controller.url))
        #expect(controller.pendingPairing?.isWaiting == true)

        #expect(try await redeem(pairing.code.digits).status == 403)
        _ = try await MCPTestFixtures.initialize(controller, token: pairing.token)
        #expect(controller.pairedClients.count == 1)
    }

    @Test func wrongCodesUseUpThePairingCode() async throws {
        controller.beginPairing()
        let code = try #require(controller.pendingPairing?.code)
        let wrong = code.digits == "000000" ? "111111" : "000000"
        for _ in 0..<MCPPairingCode.allowedFailures {
            #expect(try await redeem(wrong).status == 403)
        }
        #expect(try await redeem(code.digits).status == 403)
        #expect(controller.log.first?.tool == "pair")
        #expect(controller.log.first?.outcome == .refused)
    }

    @Test func pairingCodesExpire() async throws {
        controller.beginPairing()
        let code = try #require(controller.pendingPairing?.code)
        clock.advance(by: MCPPairingCode.lifetime)
        #expect(try await redeem(code.digits).status == 403)
    }

    @Test func codesArePostedAndNeedAPairing() async throws {
        #expect(try await redeem("123456").status == 403)
        let get = try await send(MCPTestFixtures.request("GET", path: MCPEndpoint.pairingPath, token: nil))
        #expect(get.status == 405)
        let website = MCPTestFixtures.request(path: MCPEndpoint.pairingPath, token: nil, body: ["code": "123456"], headers: ["Origin": "https://evil.example"])
        #expect(try await send(website).status == 403)
    }

    @Test func revokingDisconnectsTheClientAndVoidsItsToken() async throws {
        let (client, token) = MCPTestFixtures.pair(in: controller, at: clock.now)
        let (other, otherToken) = MCPTestFixtures.pair(.cursor, in: controller, at: clock.now)
        try secrets.setSecret(token, named: client.secretName)
        _ = try await MCPTestFixtures.initialize(controller, token: token)
        _ = try await MCPTestFixtures.initialize(controller, token: otherToken, clientName: "cursor")

        controller.revoke(client.id)

        #expect(controller.pairedClients.map(\.id) == [other.id])
        #expect(controller.sessions.map(\.pairedClientID) == [other.id])
        #expect(try secrets.secret(named: client.secretName) == nil)
        let refused = try await send(MCPTestFixtures.request(token: token, body: MCPTestFixtures.rpc("initialize", params: MCPTestFixtures.initializeParams())))
        #expect(refused.status == 401)
    }

    @Test func pairingsSurviveARelaunch() async throws {
        controller.beginPairing()
        let token = try #require(controller.pendingPairing?.token)
        _ = try await MCPTestFixtures.initialize(controller, token: token)
        let client = try #require(controller.pairedClients.first)

        clock.advance(by: 3600)
        let relaunched = MCPTestFixtures.controller(secrets: secrets, defaults: defaults, clock: clock)
        #expect(relaunched.pairedClients == [client])
        #expect(try relaunched.status(of: client) == .idle(since: #require(client.lastSeenAt), everConnected: true))
        _ = try await MCPTestFixtures.initialize(relaunched, token: token)
        #expect(relaunched.status(of: client) == .connected(lastCall: clock.now))
    }

    @Test func aClientNeverConnectedIsIdleSinceItWasPaired() {
        let (client, _) = MCPTestFixtures.pair(in: controller, at: clock.now)
        #expect(controller.status(of: client) == .idle(since: clock.now, everConnected: false))
    }
}
