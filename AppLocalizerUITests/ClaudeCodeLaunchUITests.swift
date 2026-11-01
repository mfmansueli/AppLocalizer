//
//  ClaudeCodeLaunchUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Claude Code started by AppLocalizer, through the `cc-*` DEBUG scenes in
/// `ClaudeCodeDebugScenes`: a pretend helper prints canned Claude Code
/// output, so nothing runs. Buttons that would open a Save panel, Terminal
/// or write to the clipboard are checked, never clicked.
@MainActor
final class ClaudeCodeLaunchUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Setup

    func testSetupAsksForTheHelperBeforeContinuing() {
        launch(scene: "cc-setup")
        let install = app.buttons["assistantSetup.launch.install"]
        XCTAssertTrue(install.waitForExistence(timeout: 10))
        XCTAssertEqual(install.label, "Install Helper…")
        // The folder comes once the helper is in place.
        XCTAssertFalse(element("assistantSetup.launch.folder").exists)
        XCTAssertFalse(app.buttons["assistantSetup.continue"].isEnabled)
    }

    func testSetupRunsTheTestItselfAndConnects() {
        launch(scene: "cc-setup-installed")
        let installed = element("assistantSetup.launch.installed")
        XCTAssertTrue(installed.waitForExistence(timeout: 10))
        let summary = installed.label + " " + ((installed.value as? String) ?? "")
        XCTAssertTrue(summary.contains("Helper installed"), summary)
        XCTAssertEqual(text(of: element("assistantSetup.launch.folder")), "~/Developer/Lumen")
        let next = app.buttons["assistantSetup.continue"]
        XCTAssertTrue(next.isEnabled)

        next.click()
        XCTAssertTrue(element("assistantSetup.connected").waitForExistence(timeout: 10))
        XCTAssertTrue(element("assistantSetup.launch.fromNowOn").exists)
        XCTAssertEqual(next.label, "Done")
    }

    // MARK: - Runs

    func testAskStartsClaudeCodeAndShowOutputCanStopIt() {
        launch(scene: "cc-ask")
        let popover = element("ask.popover")
        XCTAssertTrue(popover.waitForExistence(timeout: 10))
        let step = popover.descendants(matching: .any)["claudeCode.run.step"]
        XCTAssertTrue(step.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: popover.descendants(matching: .any)["claudeCode.run.status"]).hasPrefix("Working in ~/Developer/Lumen"))
        XCTAssertTrue(waitForText("Read CHANGELOG.md", in: step))

        popover.buttons["claudeCode.run.output"].click()
        let phase = element("claudeCode.output.phase")
        XCTAssertTrue(phase.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: phase), "Working")
        XCTAssertTrue(text(of: element("claudeCode.output.summary")).contains("~/Developer/Lumen"))

        app.buttons["claudeCode.output.stop"].click()
        XCTAssertTrue(waitForText("Stopped", in: phase))
    }

    func testALoginProblemSaysHowToGetPastIt() {
        launch(scene: "cc-login")
        let status = element("claudeCode.run.status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForText("Claude Code needs you to log in", in: status))
        // Never clicked: Terminal would open.
        XCTAssertEqual(app.buttons["claudeCode.run.terminal"].label, "Open in Terminal")
        XCTAssertEqual(app.buttons["claudeCode.run.retry"].label, "Try Again")
        XCTAssertTrue(app.buttons["claudeCode.run.copyPrompt"].exists)
    }

    func testRefusedStepsAreListedWithTheResumeCommand() {
        launch(scene: "cc-denied")
        let denials = element("claudeCode.run.denials")
        XCTAssertTrue(denials.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: element("claudeCode.run.status").firstMatch), "Finished · 2 steps weren’t allowed")
        XCTAssertTrue(app.buttons["claudeCode.run.resume"].exists)
        XCTAssertTrue(app.buttons["claudeCode.run.dismiss"].exists)
    }

    func testShowOutputListsWhatTheRunDid() {
        launch(scene: "cc-output")
        let output = element("claudeCode.output")
        XCTAssertTrue(output.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: element("claudeCode.output.phase")), "Finished")
        XCTAssertTrue(text(of: element("claudeCode.output.summary")).contains("calls to AppLocalizer"))
        XCTAssertTrue(element("claudeCode.output.result").exists)
        XCTAssertTrue(app.buttons["claudeCode.output.resume"].exists)

        app.buttons["claudeCode.output.done"].click()
        XCTAssertTrue(output.waitForNonExistence(timeout: 5))
    }

    func testTheAssistantButtonListsRunsAndStopsOne() {
        launch(scene: "cc-toolbar")
        let runs = element("assistant.runs")
        XCTAssertTrue(runs.waitForExistence(timeout: 10))
        let stops = runs.buttons.matching(identifier: "assistant.runs.stop")
        XCTAssertTrue(waitForCount(2, of: stops))

        stops.firstMatch.click()
        XCTAssertTrue(waitForCount(1, of: stops))
    }

    // MARK: - Without the helper, and Settings

    func testWithoutTheHelperAskOffersToSetItUp() {
        launch(scene: "cc-hint")
        let hint = element("claudeCode.hint")
        XCTAssertTrue(hint.waitForExistence(timeout: 10))
        // Never clicked: it opens a Save panel.
        XCTAssertTrue(app.buttons["claudeCode.hint.setUp"].exists)
        XCTAssertFalse(element("claudeCode.run").exists)
    }

    func testSettingsShowsTheHelperFoldersAndPermissions() {
        launch(scene: "cc-settings")
        let helper = element("settings.ai.launch.helper")
        XCTAssertTrue(helper.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: helper), "Helper installed")
        XCTAssertTrue(app.buttons["settings.ai.launch.check"].exists)
        XCTAssertEqual(app.buttons["settings.ai.launch.folder.6450000001"].label, "Change…")
        XCTAssertEqual(app.buttons["settings.ai.launch.folder.6450000003"].label, "Choose…")
        XCTAssertTrue(element("settings.ai.launch.permissions").exists)
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    /// Waits for `element` to read `expected`, as runs move on.
    private func waitForText(_ expected: String, in element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if element.exists, text(of: element) == expected { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.1))
        }
        return false
    }

    private func waitForCount(_ count: Int, of query: XCUIElementQuery, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if query.count == count { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.1))
        }
        return false
    }
}
