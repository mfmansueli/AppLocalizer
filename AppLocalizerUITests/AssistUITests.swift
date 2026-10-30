//
//  AssistUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Suggestions from an API key and Claude Code's Age Rating and
/// Accessibility answers, opened by board 19's DEBUG scenes. The canned
/// service answers instead of the vendor, and the key is typed, never
/// pasted, so the clipboard stays untouched.
@MainActor
final class AssistUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Setup with a key

    func testAKeyIsCheckedTestedAndSavedAtTheEnd() {
        app.launch(debugScene: "setup-key-1")
        XCTAssertTrue(element("assistantSetup.sheet").waitForExistence(timeout: 10))
        let next = app.buttons["assistantSetup.continue"]
        next.click()
        XCTAssertEqual(text(of: element("assistantSetup.stepCount")), "Step 2 of 4")
        XCTAssertFalse(next.isEnabled)

        let key = element("keySetup.key")
        key.click()
        key.typeText("sk-ant-api03-uitest-0123456789-abcd")
        app.buttons["keySetup.check"].click()
        let status = element("keySetup.status")
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(wait(for: status, toContain: "Key works"), status.debugDescription)
        XCTAssertTrue(next.isEnabled)

        next.click()
        XCTAssertEqual(text(of: element("assistantSetup.stepCount")), "Step 3 of 4")
        XCTAssertTrue(element("keySetup.reviews").exists)
        next.click()
        let works = element("keySetup.works")
        XCTAssertTrue(works.waitForExistence(timeout: 10))
        XCTAssertTrue(Self.showing("Private diary, mood & prompts").evaluate(with: works), works.debugDescription)
        XCTAssertEqual(next.label, "Done")
        next.click()
        XCTAssertTrue(element("assistantSetup.sheet").waitForNonExistence(timeout: 5))
        XCTAssertEqual(element("workspace.assistantIndicator").label, "Assistant, Ready")
    }

    func testARejectedKeySaysWhyAndCantContinue() {
        app.launch(debugScene: "setup-key-bad")
        let status = element("keySetup.status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(wait(for: status, toContain: "rejected this key (401)"), status.debugDescription)
        XCTAssertFalse(app.buttons["assistantSetup.continue"].isEnabled)
    }

    // MARK: - Store Page

    func testGenerateShowsWhatItSendsThenAddsTheSuggestions() {
        app.launch(debugScene: "sp-key-ask")
        let popover = element("generate.popover")
        XCTAssertTrue(popover.waitForExistence(timeout: 10))
        let sends = element("generate.sends")
        XCTAssertTrue(sends.waitForExistence(timeout: 5))
        XCTAssertTrue(sends.descendants(matching: .any).matching(Self.showing("23 commit messages since v1.3")).firstMatch.exists, sends.debugDescription)
        XCTAssertTrue(text(of: element("generate.total")).contains("billed to your Anthropic account"))

        app.buttons["generate.go"].click()
        let toast = element("toast.text")
        XCTAssertTrue(toast.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: toast), "Anthropic API sent 3 suggestions. Nothing changes until you accept them.")
        let whatsNew = element("storePage.field.whatsNew")
        XCTAssertTrue(whatsNew.descendants(matching: .any)["suggestion.card"].waitForExistence(timeout: 5))
    }

    func testWithAKeyAppInformationSaysWhatNeedsTheCode() {
        app.launch(debugScene: "in-key")
        let note = element("suggestions.keyNote")
        XCTAssertTrue(note.waitForExistence(timeout: 10))
        XCTAssertTrue(note.descendants(matching: .any).matching(Self.showing("come from Lumen Journal’s code")).firstMatch.exists, note.debugDescription)
        XCTAssertFalse(app.buttons["suggestions.ask"].isEnabled)

        app.buttons["suggestions.addAssistant"].click()
        XCTAssertTrue(element("assistantSetup.sheet").waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: element("assistantSetup.stepCount")), "Step 1 of 4")
        XCTAssertTrue(element("assistantSetup.client.claudeCode").exists)
    }

    // MARK: - Age Rating and Accessibility

    func testAnAgeRatingAnswerGoesInAsTheQuestionsAnswer() {
        app.launch(debugScene: "in-age")
        let wellness = element("appInformation.suggestions.age.wellness")
        XCTAssertTrue(wellness.waitForExistence(timeout: 10))
        wellness.buttons["suggestion.accept"].click()
        let provenance = wellness.descendants(matching: .any)["suggestion.provenanceText"]
        XCTAssertTrue(provenance.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: provenance), "Accepted Claude Code’s suggestion.")
        XCTAssertTrue(text(of: element("toast.text")).hasPrefix("Accepted the Health or wellness topics suggestion."))
    }

    func testAcceptAllDeclaresTheWatchsFeatures() {
        app.launch(debugScene: "in-ax")
        XCTAssertTrue(element("appInformation.accessibility.suggestions").waitForExistence(timeout: 10))
        let acceptAll = app.buttons["suggestions.acceptAll"]
        XCTAssertTrue(acceptAll.waitForExistence(timeout: 5))
        XCTAssertEqual(acceptAll.label, "Accept All (4)")
        acceptAll.click()
        XCTAssertTrue(text(of: element("toast.text")).hasPrefix("Accepted 4 suggestions on Accessibility · Apple Watch."))
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    /// macOS keeps a text's words in its value, a combined element's in
    /// its label.
    private static func showing(_ text: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)
    }

    /// The canned check takes a moment.
    private func wait(for element: XCUIElement, toContain text: String, timeout: TimeInterval = 5) -> Bool {
        XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: Self.showing(text), object: element)], timeout: timeout) == .completed
    }
}
