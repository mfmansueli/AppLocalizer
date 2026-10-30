//
//  AssistantSetupViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// "Set Up Your AI Assistant": the four steps against an in-memory MCP
/// server, from choosing a client to its first call, or finishing without
/// testing.
@MainActor
@Suite("AssistantSetupViewModel")
struct AssistantSetupViewModelTests {
    private let clock = TestClock()

    private func setup(_ assistants: MCPServerController) -> AssistantSetupViewModel {
        let keyAssistant = KeyAssistantController(service: StubKeyAssistantService(), secrets: InMemorySecretStore(), defaults: nil)
        return AssistantSetupViewModel(assistants: assistants, keyAssistant: keyAssistant, appName: "Lumen Journal")
    }

    @Test func walksTheStepsAndPairsTheChosenClient() {
        let assistants = MCPTestFixtures.controller(clock: clock)
        let setup = setup(assistants)
        #expect(setup.step == .assistant)
        #expect(!setup.canGoBack)

        setup.choose(.cursor)
        #expect(!setup.advance())
        #expect(setup.step == .server)
        #expect(!setup.canContinue)
        #expect(!setup.advance())

        setup.setServerOn(true)
        setup.editsDrafts = true
        #expect(!setup.advance())
        #expect(setup.step == .snippet)
        #expect(assistants.pendingPairing?.kind == .cursor)
        #expect(assistants.editsDrafts)
        #expect(assistants.allowedProposals.isSuperset(of: [.storeText, .appInformation]))

        #expect(setup.copySnippet() != nil)
        #expect(setup.footnote == "Copied. Paste it, then continue.")
        #expect(assistants.assistantStatus == .waiting(client: "Cursor"))

        #expect(!setup.advance())
        #expect(setup.step == .test)
        #expect(setup.continueTitle == "Finish Without Testing")
        #expect(setup.advance())
        #expect(assistants.pairedClients.map(\.kind) == [.cursor])
        #expect(setup.finishedAnnouncement == "Saved. The Assistant button turns green when Cursor first calls AppLocalizer.")
    }

    @Test func onceTheClientCallsItsDone() throws {
        let assistants = MCPTestFixtures.controller(clock: clock)
        assistants.setEnabled(true)
        assistants.beginPairing(kind: .claudeCode)
        assistants.markPairingCopied()
        let setup = setup(assistants)
        #expect(setup.step == .test)

        let pairing = try #require(assistants.pendingPairing)
        assistants.pendingPairing?.connectedClient = MCPPairedClient(id: pairing.clientID, kind: .claudeCode, name: "Claude Code", pairedAt: clock.now)
        #expect(setup.isConnected)
        #expect(setup.continueTitle == "Done")
        #expect(!setup.canGoBack)
        #expect(setup.connectedText == "Claude Code called AppLocalizer. It can read and suggest; it can’t push.")
        #expect(setup.finishedAnnouncement.hasPrefix("Claude Code is connected."))
    }

    @Test func cancellingForgetsAClientThatNeverConnected() {
        let assistants = MCPTestFixtures.controller(clock: clock)
        let setup = setup(assistants)
        setup.setServerOn(true)
        _ = setup.advance()
        _ = setup.advance()
        #expect(assistants.pendingPairing != nil)
        setup.cancel()
        #expect(assistants.pendingPairing == nil)
        #expect(assistants.pairedClients.isEmpty)
    }

    @Test func choosingAKeyLeavesTheServerAlone() {
        let assistants = MCPTestFixtures.controller(clock: clock)
        let setup = setup(assistants)
        setup.choose(.apiKey)
        #expect(setup.usesKey)
        #expect(!setup.advance())
        #expect(setup.step == .server)
        setup.choose(.assistant)
        #expect(setup.usesKey)
        setup.cancel()
        #expect(!assistants.isEnabled)
        #expect(assistants.pendingPairing == nil)
    }

    @Test func aClientPairedWithoutTestingReopensOnTheTest() {
        let assistants = MCPTestFixtures.controller(clock: clock)
        assistants.setEnabled(true)
        MCPTestFixtures.pair(.codex, in: assistants, at: clock.now)
        let setup = setup(assistants)
        #expect(setup.step == .test)
        #expect(setup.kind == .codex)
        #expect(!setup.isConnected)
    }
}
