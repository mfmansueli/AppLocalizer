//
//  AssistantWorkspaceUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// An assistant at work in the main window, opened by the `ai-*` DEBUG
/// scenes: the toolbar indicator and its proposals, Review & Push filtered
/// to one assistant, and Translate Missing handing the job to an assistant.
/// Nothing is copied, so the clipboard stays untouched.
@MainActor
final class AssistantWorkspaceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testTheIndicatorOpensTheAssistantsProposals() {
        launch(scene: "ai-streaming")
        let indicator = element("workspace.assistantIndicator")
        XCTAssertTrue(indicator.waitForExistence(timeout: 10))
        XCTAssertEqual(indicator.label, "Claude Code is proposing changes")

        indicator.click()
        let popover = element("workspace.assistantPopover")
        XCTAssertTrue(popover.waitForExistence(timeout: 5))
        XCTAssertTrue(popover.staticTexts["Waiting for you"].exists)

        popover.buttons["workspace.reviewProposals"].click()
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 5))
        XCTAssertTrue(claudeCodeFilter.waitForExistence(timeout: 5))
        XCTAssertTrue(claudeCodeFilter.isSelected)
    }

    func testReviewProposalsIsFilteredToTheAssistant() {
        launch(scene: "ai-review")
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 10))
        XCTAssertTrue(claudeCodeFilter.waitForExistence(timeout: 5))
        XCTAssertTrue(claudeCodeFilter.isSelected)
        XCTAssertTrue(app.buttons["Reject All from Claude Code"].exists)
    }

    func testTranslateMissingHandsTheJobToTheAssistant() {
        launch(scene: "ai-translate")
        let panel = element("storePage.translate.assistant")
        XCTAssertTrue(panel.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: element("storePage.translate.slashCommand")).hasPrefix("/mcp__applocalizer__translate_missing Lumen"))
        XCTAssertTrue(text(of: element("storePage.translate.prompt")).contains("“Face ID”"))
        XCTAssertTrue(element("storePage.translate.waiting").exists)

        // Never clicked: it would write to the clipboard.
        let copy = app.buttons["storePage.translate.copyPrompt"]
        XCTAssertTrue(copy.exists)
        XCTAssertEqual(copy.label, "Waiting for Claude Code…")
        XCTAssertFalse(app.buttons["storePage.translate.start"].exists)
        XCTAssertFalse(element("storePage.translate.locale.ko").exists)
    }

    // MARK: - Helpers

    /// The Review & Push source segment for Claude Code, e.g. "Claude Code 12".
    private var claudeCodeFilter: XCUIElement {
        element("review.sourceFilter").radioButtons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Claude Code"))
            .firstMatch
    }

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
