//
//  ScreenshotsProposalsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Store Page → Screenshots' Captures tab and the assistant's Proposals
/// sheet, driven through the DEBUG scenes in
/// `ScreenshotsProposalsDebugScenes` (sample captures and proposals;
/// nothing leaves the Mac): importing a fastlane folder after settling a
/// row that needs you, accepting some of the proposed captions, rebasing a
/// stale template proposal, and rejecting one. The prompt is never copied.
@MainActor
final class ScreenshotsProposalsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Captures

    func testImportingAfterSkippingAnAmbiguousLocale() {
        app.launch(debugScene: "capt-match")
        let importButton = app.buttons["captures.import"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 15))
        XCTAssertEqual(importButton.label, "Import 53 Captures")

        // "pt" could be Portuguese (Brazil) or (Portugal); skip that file.
        let portuguese = app.popUpButtons.matching(NSPredicate(format: "value == %@", "Portuguese (Brazil)")).firstMatch
        XCTAssertTrue(portuguese.waitForExistence(timeout: 5))
        portuguese.click()
        let skip = app.menuItems["Skip it"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.click()
        XCTAssertTrue(waitForLabel(importButton, "Import 52 Captures"), importButton.label)

        importButton.click()
        let notice = element("screenshots.notice")
        XCTAssertTrue(notice.waitForExistence(timeout: 10))
        // A banner is a container: its title is one of its texts.
        let prefix = "52 captures imported for 10 locales."
        let message = notice.descendants(matching: .any)
            .matching(NSPredicate(format: "value BEGINSWITH %@ OR label BEGINSWITH %@", prefix, prefix)).firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: 10))
    }

    func testTheCoverageListsEveryLocale() {
        app.launch(debugScene: "capt")
        let summary = element("captures.summary")
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: summary).hasPrefix("70 captures · fastlane"), text(of: summary))
        XCTAssertTrue(element("captures.coverage.de-DE").exists)
        XCTAssertTrue(app.buttons["captures.importMore"].exists)
    }

    // MARK: - Proposals

    func testAcceptingSomeOfTheProposedCaptions() {
        app.launch(debugScene: "prop-cap")
        let sheet = element("proposals.sheet")
        XCTAssertTrue(sheet.waitForExistence(timeout: 15))
        let acceptSelected = app.buttons["proposals.acceptSelected"]
        XCTAssertTrue(acceptSelected.waitForExistence(timeout: 5))
        XCTAssertFalse(acceptSelected.isEnabled)

        // Untick slot 5's caption (0-based slot 4).
        let privacy = element("proposals.caption.de-DE.4").checkBoxes["proposals.caption.toggle"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        privacy.click()
        XCTAssertTrue(waitForLabel(acceptSelected, "Accept 2 Selected"), acceptSelected.label)
        XCTAssertTrue(acceptSelected.isEnabled)
        acceptSelected.click()

        let outcome = element("proposals.detail.outcome")
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForText(outcome, beginningWith: "Partly accepted."), text(of: outcome))
        XCTAssertTrue(app.buttons["proposals.done"].exists)
    }

    func testRebasingAStaleProposalWithTheAssistantsValue() {
        app.launch(debugScene: "prop-stale")
        XCTAssertTrue(element("proposals.stale").waitForExistence(timeout: 15))
        let accept = app.buttons["proposals.acceptTemplate"]
        XCTAssertFalse(accept.exists)

        let theirs = app.buttons["proposals.useTheirs"]
        XCTAssertTrue(theirs.waitForExistence(timeout: 5))
        theirs.click()
        app.buttons["proposals.rebase"].click()

        XCTAssertTrue(element("proposals.stale").waitForNonExistence(timeout: 10))
        XCTAssertTrue(accept.waitForExistence(timeout: 5))
        XCTAssertTrue(accept.isEnabled)
        XCTAssertEqual(accept.label, "Accept as v5")
    }

    func testRejectingATemplateProposal() {
        app.launch(debugScene: "prop-tpl")
        let reject = app.buttons["proposals.reject"]
        XCTAssertTrue(reject.waitForExistence(timeout: 15))
        XCTAssertTrue(element("proposals.stressStrip").exists)
        reject.click()

        let outcome = element("proposals.detail.outcome")
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForText(outcome, beginningWith: "Rejected."), text(of: outcome))
        XCTAssertFalse(app.buttons["proposals.acceptTemplate"].exists)
        app.buttons["proposals.done"].click()
        XCTAssertTrue(element("proposals.sheet").waitForNonExistence(timeout: 5))
    }

    func testADisconnectedAssistantIsShownInTheSheet() {
        app.launch(debugScene: "prop-disc")
        XCTAssertTrue(element("proposals.sheet").waitForExistence(timeout: 15))
        XCTAssertTrue(element("proposals.disconnected").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["proposals.acceptAll"].exists)
    }

    // MARK: - Helpers

    private func waitForText(_ element: XCUIElement, beginningWith prefix: String) -> Bool {
        let predicate = NSPredicate(format: "value BEGINSWITH %@ OR label BEGINSWITH %@", prefix, prefix)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 10) == .completed
    }

    private func waitForLabel(_ element: XCUIElement, _ label: String) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 10) == .completed
    }

    /// A static text's string is its value on macOS; a button's is its label.
    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }
}
