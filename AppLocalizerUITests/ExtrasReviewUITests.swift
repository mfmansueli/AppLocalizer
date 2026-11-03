//
//  ExtrasReviewUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Autopilot's extras in Review & Push (the product page header, the
/// search image and the App Previews) and Test with Product Page
/// Optimization…, driven through the DEBUG scenes in
/// `ExtrasPushDebugScenes`: a simulated App Store Connect, so nothing
/// leaves the Mac.
@MainActor
final class ExtrasReviewUITests: XCTestCase {
    private var app: XCUIApplication!
    private let appID = "6450000001"

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    /// The extras have their own section and push; the German header has a
    /// discount, so it stays out and says why.
    func testExtrasAreListedAndAnErrorKeepsThatImageOut() {
        app.launch(debugScene: "shots-review-extras")
        let section = element("review.extras.section.\(appID)")
        XCTAssertTrue(section.waitForExistence(timeout: 30))
        let push = app.buttons["review.extras.push.\(appID)"]
        scrollReview(by: -400, until: push)
        XCTAssertTrue(app.buttons["Push 47 Extras"].exists)

        let german = app.checkBoxes["review.extras.check.header-de-DE"]
        scrollReview(by: -400, until: german)
        XCTAssertTrue(german.exists)
        XCTAssertFalse(german.isEnabled, "A header with an error can't be pushed")

        let findings = element("review.extras.findings.header")
        scrollReview(by: -400, until: findings)
        XCTAssertTrue(text(of: findings).contains("German header: ‘−50%’ — discounts and percentages aren’t allowed here."), text(of: findings))
        XCTAssertTrue(app.buttons["review.extras.test.header"].exists)
    }

    func testPushingTheExtrasShowsWhenTheyreDone() {
        app.launch(debugScene: "shots-review-extras")
        let push = app.buttons["review.extras.push.\(appID)"]
        XCTAssertTrue(push.waitForExistence(timeout: 30))
        scrollReview(by: -400, until: push)
        push.click()
        let progress = element("review.extras.progress")
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["All 47 extras pushed"].waitForExistence(timeout: 120))
    }

    /// A run that made only extras, for an app without a screenshot set:
    /// they're listed, App Preview included, and Discard All takes them
    /// out at once with an Undo.
    func testDiscardAllTakesTheExtrasOutWithUndo() {
        app.launch(debugScene: "shots-review-extras-only")
        XCTAssertTrue(element("review.extras.section.\(appID)").waitForExistence(timeout: 30))
        let header = app.checkBoxes["review.extras.check.header-en-US"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        let preview = app.checkBoxes["review.extras.check.iphone-en-US"]
        scrollReview(by: -400, until: preview)
        XCTAssertTrue(preview.exists, "The App Preview waits without a screenshot set")

        let discard = app.buttons["review.discardAll"]
        XCTAssertTrue(discard.isEnabled)
        discard.click()
        let note = element("review.extras.discarded.\(appID)")
        XCTAssertTrue(note.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: note).hasSuffix("extras discarded: App Store Connect keeps what it has."), text(of: note))
        XCTAssertFalse(header.exists)
        XCTAssertFalse(preview.exists)
        XCTAssertFalse(discard.isEnabled, "Nothing left to discard")
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = "Extras discarded"
        attachment.lifetime = .keepAlways
        add(attachment)

        element("review.extras.undo.\(appID)").click()
        XCTAssertTrue(header.waitForExistence(timeout: 10), "Undo brings them back")
        XCTAssertFalse(note.exists)
        XCTAssertTrue(discard.isEnabled)
    }

    /// The variant is ready: Create Test makes it a draft through the API.
    func testATestIsCreatedAsADraft() {
        app.launch(debugScene: "shots-ppo")
        XCTAssertTrue(element("ppo.sheet").waitForExistence(timeout: 30))
        XCTAssertTrue(text(of: element("ppo.explanation")).contains(
            "Tests one idea at a time. Apple splits traffic between your current page and this treatment; results appear in App Store Connect."
        ))
        let create = app.buttons["ppo.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        XCTAssertTrue(create.isEnabled)
        create.click()
        let outcome = element("ppo.outcome")
        XCTAssertTrue(outcome.waitForExistence(timeout: 60))
        XCTAssertTrue(text(of: outcome).contains("Test created as a draft"), text(of: outcome))
        XCTAssertFalse(app.buttons["ppo.showInFinder"].exists)
    }

    /// App Store Connect won't take the artwork on a treatment: both
    /// variants are exported instead, and the sheet never claims a test.
    func testWhenTheAPICantPlaceTheArtworkBothVariantsAreExported() {
        app.launch(debugScene: "shots-ppo-export")
        let outcome = element("ppo.outcome")
        XCTAssertTrue(outcome.waitForExistence(timeout: 60))
        let said = text(of: outcome)
        XCTAssertTrue(said.contains("Exported for App Store Connect"), said)
        XCTAssertTrue(said.contains("The test wasn’t created."), said)
        XCTAssertFalse(said.contains("Test created"), said)
        XCTAssertTrue(app.buttons["ppo.showInFinder"].exists)
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// What VoiceOver reads for a combined element.
    private func text(of element: XCUIElement) -> String {
        "\(element.label) \(element.value as? String ?? "")"
    }

    /// Scrolls Review & Push (down for a negative `deltaY`) until `target`
    /// exists and is inside the window.
    private func scrollReview(by deltaY: CGFloat, until target: XCUIElement) {
        let window = app.windows.firstMatch
        let sheet = element("review.sheet")
        for _ in 0..<30 {
            if target.exists, window.frame.contains(target.frame) { return }
            sheet.scroll(byDeltaX: 0, deltaY: deltaY)
        }
    }
}
