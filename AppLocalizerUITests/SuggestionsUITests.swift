//
//  SuggestionsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Field suggestions and the assistant setup, opened by board 17's DEBUG
/// scenes: the Assistant button before setup, the overview's card, the
/// setup sheet's first steps, accepting and undoing on the Store Page, and
/// App Information's cards. Nothing is copied, so the clipboard stays
/// untouched (no Copy, no Ask).
@MainActor
final class SuggestionsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Assistant button and overview

    func testTheAssistantButtonIsThereBeforeSetupAndOpensIt() {
        app.launch(debugScene: "ov-first")
        let indicator = element("workspace.assistantIndicator")
        XCTAssertTrue(indicator.waitForExistence(timeout: 10))
        XCTAssertEqual(indicator.label, "Assistant, Not set up")

        indicator.click()
        let popover = element("workspace.assistantPopover")
        XCTAssertTrue(popover.waitForExistence(timeout: 5))
        popover.buttons["assistant.setUp"].click()
        let sheet = element("assistantSetup.sheet")
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: element("assistantSetup.stepCount")), "Step 1 of 4")

        app.buttons["assistantSetup.cancel"].click()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))
    }

    func testTheOverviewIntroducesTheAssistantUntilHidden() {
        app.launch(debugScene: "ov-first")
        let card = element("overview.assistantIntro")
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: element("overview.assistantIntro.status")), "Not set up")
        XCTAssertTrue(element("overview.suggestionsCard").exists)

        app.buttons["overview.assistantIntro.hide"].click()
        XCTAssertTrue(card.waitForNonExistence(timeout: 5))
    }

    func testOnceConnectedTheOverviewNamesTheAssistant() {
        app.launch(debugScene: "ov-connected")
        let card = element("overview.assistantConnected")
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        // One element for VoiceOver: "Claude Code is connected, Project …".
        let summary = element("overview.assistantConnected.summary").label
        XCTAssertTrue(summary.contains("Claude Code is connected"))
        XCTAssertTrue(summary.contains("Project ~/Developer/Lumen"))
        XCTAssertFalse(element("overview.assistantIntro").exists)
        XCTAssertEqual(text(of: element("overview.suggestionsCard.count")), "8 to review")
    }

    // MARK: - Setup

    func testSetupNeedsTheServerOnBeforeTheCommand() {
        app.launch(debugScene: "setup-1")
        XCTAssertTrue(element("assistantSetup.sheet").waitForExistence(timeout: 10))
        element("assistantSetup.client.cursor").click()
        let next = app.buttons["assistantSetup.continue"]
        next.click()
        XCTAssertEqual(text(of: element("assistantSetup.stepCount")), "Step 2 of 4")
        XCTAssertFalse(next.isEnabled)

        element("assistantSetup.server").click()
        XCTAssertTrue(next.isEnabled)
        next.click()
        XCTAssertEqual(text(of: element("assistantSetup.stepCount")), "Step 3 of 4")
        XCTAssertTrue(element("assistantSetup.snippet").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["assistantSetup.back"].exists)
    }

    func testTheLastStepSaysWhenTheClientConnected() {
        app.launch(debugScene: "setup-done")
        XCTAssertTrue(element("assistantSetup.connected").waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["assistantSetup.continue"].label, "Done")
    }

    // MARK: - Store Page

    func testAcceptingASuggestionSaysWhoAndUndoesFromTheToast() {
        app.launch(debugScene: "sp-cc")
        let subtitle = element("storePage.field.subtitle")
        XCTAssertTrue(subtitle.waitForExistence(timeout: 10))
        let card = subtitle.descendants(matching: .any)["suggestion.card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.buttons["suggestion.accept"].click()

        let provenance = subtitle.descendants(matching: .any)["suggestion.provenanceText"]
        XCTAssertTrue(provenance.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: provenance), "Accepted Claude Code’s suggestion.")
        XCTAssertFalse(card.exists)

        let toast = element("toast")
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        toast.buttons["toast.undo"].click()
        XCTAssertTrue(provenance.waitForNonExistence(timeout: 5))
        XCTAssertTrue(subtitle.descendants(matching: .any)["suggestion.card"].waitForExistence(timeout: 5))
    }

    /// The accepted subtitle ("Private diary, mood & prompts") covers two
    /// keywords, so the built-in check offers to drop them right after.
    func testAcceptAllReviewsTheLanguageAndChecksTheResult() {
        app.launch(debugScene: "sp-cc")
        let acceptHere = app.buttons["languageBar.acceptHere"]
        XCTAssertTrue(acceptHere.waitForExistence(timeout: 10))
        XCTAssertEqual(acceptHere.label, "Accept 4 in English")
        acceptHere.click()
        XCTAssertTrue(text(of: element("toast.text")).hasPrefix("Accepted 4 in English."))
        let one = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Accept 1 in English"), object: acceptHere)
        XCTAssertEqual(XCTWaiter.wait(for: [one], timeout: 5), .completed)

        let keywords = element("storePage.field.keywords")
        let reason = keywords.descendants(matching: .any)["suggestion.reason"]
        XCTAssertTrue(reason.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: reason).contains("“diary” and “mood”"))
    }

    func testSuggestionsArrivingShowTheirProgress() {
        app.launch(debugScene: "sp-streaming")
        let banner = element("suggestions.streaming")
        XCTAssertTrue(banner.waitForExistence(timeout: 10))
        XCTAssertTrue(banner.label.contains("Sending suggestions · 2 of 4"))
        XCTAssertFalse(app.buttons["suggestions.ask"].exists)
    }

    // MARK: - App Information

    func testAppInformationShowsSuggestionsUnderTheirFields() {
        app.launch(debugScene: "in-general")
        let general = element("appInformation.pageRow.general")
        XCTAssertTrue(general.waitForExistence(timeout: 10))
        XCTAssertTrue(general.label.contains("3 suggested"), general.label)

        let copyright = element("appInformation.suggestions.copyright")
        XCTAssertTrue(copyright.waitForExistence(timeout: 5))
        copyright.buttons["suggestion.accept"].click()
        let field = element("appInformation.general.copyright")
        XCTAssertTrue(text(of: field).hasSuffix("Northpier Studio"))
        XCTAssertFalse(text(of: field).contains("2025"))
        XCTAssertTrue(copyright.descendants(matching: .any)["suggestion.provenanceText"].waitForExistence(timeout: 5))
        XCTAssertTrue(general.label.contains("2 suggested"), general.label)
    }

    func testAppReviewTakesThePreviousVersionsPhone() {
        app.launch(debugScene: "in-review")
        let phone = element("appInformation.suggestions.contactPhone")
        XCTAssertTrue(phone.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: phone.descendants(matching: .any)["suggestion.reason"]).contains("1.3"))
        phone.buttons["suggestion.accept"].click()
        XCTAssertEqual(text(of: element("appInformation.review.phone")), "+39 011 555 0142")
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }
}
