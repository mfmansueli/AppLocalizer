//
//  AssistantStatusTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// How far the person's own assistant is set up, as the Assistant button,
/// the overview and the suggestion bars read it.
@MainActor
@Suite("AssistantStatus")
struct AssistantStatusTests {
    private let clock = TestClock()

    @Test func wordsForEachState() {
        #expect(AssistantStatus.notSetUp.title == "Not set up")
        #expect(AssistantStatus.notSetUp.setupTitle == "Set Up Assistant…")
        #expect(AssistantStatus.notSetUp.askTitle == "Set Up Assistant…")
        let waiting = AssistantStatus.waiting(client: "Cursor")
        #expect(waiting.setupTitle == "Finish Setup…")
        #expect(waiting.clientName == "Cursor")
        #expect(waiting.isWaiting)
        let connected = AssistantStatus.connected(client: "Claude Code")
        #expect(connected.askTitle == "Ask Claude Code…")
        #expect(connected.isConnected)
        #expect(connected.title == "Connected")
        let ready = AssistantStatus.ready(client: "Anthropic API")
        #expect(ready.title == "Ready")
        #expect(ready.askTitle == "Generate Suggestions…")
        #expect(ready.isReady && ready.canSuggest && !ready.isConnected)
        #expect(!waiting.canSuggest)
    }

    @Test func theControllerGoesFromNotSetUpToWaitingToConnected() {
        let controller = MCPTestFixtures.controller(clock: clock)
        #expect(controller.assistantStatus == .notSetUp)

        controller.setEnabled(true)
        #expect(controller.assistantStatus == .notSetUp)
        controller.beginPairing(kind: .claudeCode)
        #expect(controller.assistantStatus == .waiting(client: "Claude Code"))

        controller.cancelPairing()
        let paired = MCPTestFixtures.pair(.cursor, in: controller, at: clock.now)
        #expect(controller.assistantStatus == .waiting(client: "Cursor"))
        controller.noteSeen(paired.client.id, at: clock.now)
        #expect(controller.assistantStatus == .connected(client: "Cursor"))
        #expect(controller.leadingClient?.id == paired.client.id)

        controller.setEnabled(false)
        #expect(controller.assistantStatus == .notSetUp)
    }

    @Test func recentCallsAreTheClientsToolCallsNewestFirst() {
        let controller = MCPTestFixtures.controller(clock: clock)
        controller.record(client: "Claude Code", tool: "list_apps", target: "Northpier", outcome: .read, at: clock.now)
        controller.record(client: "Cursor", tool: "get_store_page", target: "Lumen", outcome: .read, at: clock.now)
        controller.record(client: "Claude Code", tool: "—", target: "", outcome: .refused, at: clock.now)
        controller.record(client: "Claude Code", tool: "suggest_fields", target: "Lumen", outcome: .proposed, at: clock.now)
        #expect(controller.recentCalls(of: "Claude Code").map(\.tool) == ["suggest_fields", "list_apps"])
    }
}
