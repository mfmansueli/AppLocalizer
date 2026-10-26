//
//  AssistantsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Settings → AI Assistants, opened by the `set-ai-*` DEBUG scenes: the
/// server switch, pairing an assistant, revoking one, and what assistants
/// may propose. The scenes' server never opens a port.
@MainActor
final class AssistantsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testTurningTheServerOnOffersPairing() {
        launch(scene: "set-ai-off")
        let server = element("settings.ai.server")
        XCTAssertTrue(server.waitForExistence(timeout: 10))
        XCTAssertTrue(element("settings.ai.can").exists)
        XCTAssertTrue(element("settings.ai.cannot").exists)
        XCTAssertFalse(app.buttons["settings.ai.pair"].exists)

        if server.switches.firstMatch.exists {
            server.switches.firstMatch.click()
        } else {
            server.click()
        }

        let pair = app.buttons["settings.ai.pair"]
        XCTAssertTrue(pair.waitForExistence(timeout: 5))
        XCTAssertTrue(pair.isEnabled)
        XCTAssertTrue(element("settings.ai.noClients").exists)
    }

    func testThePairingSheetShowsASnippetPerClientAndACode() {
        launch(scene: "set-ai-pair")
        let snippet = element("settings.ai.pairSnippet")
        XCTAssertTrue(snippet.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: snippet).hasPrefix("claude mcp add --transport http applocalizer"))
        XCTAssertTrue(text(of: snippet).contains("al_pair_"))
        XCTAssertTrue(element("settings.ai.pairCode").exists)
        XCTAssertTrue(element("settings.ai.pairWaiting").exists)

        app.radioButtons["Cursor"].firstMatch.click()
        XCTAssertTrue(text(of: snippet).contains("\"url\": \"http://127.0.0.1:47321/mcp\""))
        XCTAssertFalse(element("settings.ai.pairWaiting").exists)

        app.radioButtons["Codex"].firstMatch.click()
        XCTAssertTrue(text(of: snippet).hasPrefix("[mcp_servers.applocalizer]"))

        app.buttons["settings.ai.pairCancel"].click()
        XCTAssertTrue(snippet.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("settings.ai.noClients").exists)
    }

    func testRevokingAnAssistantAsksFirst() {
        launch(scene: "set-ai-on")
        let cursor = element("settings.ai.client.cursor")
        XCTAssertTrue(cursor.waitForExistence(timeout: 10))
        XCTAssertTrue(element("settings.ai.client.claudeCode").exists)

        app.buttons["settings.ai.revoke.cursor"].click()
        let confirm = app.windows.descendants(matching: .button)["Revoke"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.click()

        XCTAssertTrue(cursor.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("settings.ai.client.claudeCode").exists)
    }

    func testProposalsCanBeTurnedOffOneByOne() {
        launch(scene: "set-ai-on")
        let prices = app.checkBoxes["settings.ai.allow.prices"]
        XCTAssertTrue(prices.waitForExistence(timeout: 10))
        XCTAssertEqual(prices.value as? Int, 1)
        prices.click()
        XCTAssertEqual(prices.value as? Int, 0)
        XCTAssertEqual(app.checkBoxes["settings.ai.allow.storeText"].value as? Int, 1)
    }

    func testTheLogSaysWhyCallsWereRefused() {
        launch(scene: "set-ai-log")
        // Each log line reads as one element.
        let reason = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "so price proposals are off for this app"))
            .firstMatch
        XCTAssertTrue(reason.waitForExistence(timeout: 10))
        let clear = app.buttons["Clear"]
        XCTAssertTrue(clear.exists)
        clear.click()
        XCTAssertTrue(reason.waitForNonExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launchArguments = ["-AppLocalizerDebugScene", scene]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }
}
