//
//  ScreenshotsPushUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Review & Push for screenshots, driven through the DEBUG scenes in
/// `ScreenshotsPushDebugScenes` (a simulated App Store Connect; nothing
/// leaves the Mac).
@MainActor
final class ScreenshotsPushUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testReviewListsTheImagesAndDiscardCanBeUndone() {
        launch(scene: "shots-review")
        XCTAssertTrue(element("review.shots.item.ar-SA.iPhone.1").waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Push 40 Images"].exists)
        XCTAssertTrue(app.staticTexts["About 168 requests · 2 min · 5% of the hourly limit"].exists)

        app.buttons["review.shots.discard.ar-SA.iPhone.1"].click()
        XCTAssertTrue(element("review.shots.item.ar-SA.iPhone.1").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Push 39 Images"].waitForExistence(timeout: 5))

        // Undo sits under the last set, and as a link-style button it isn't
        // one of `app.buttons`.
        let undo = element("review.shots.undo")
        scrollReview(by: -1000, until: undo)
        undo.click()
        let restored = element("review.shots.item.ar-SA.iPhone.1")
        scrollReview(by: 1000, until: restored)
        XCTAssertTrue(restored.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Push 40 Images"].exists)
    }

    func testUncheckingAnImageOffersPushSelected() {
        launch(scene: "shots-review")
        let check = app.checkBoxes["review.shots.check.nl-NL.iPhone.2"]
        XCTAssertTrue(check.waitForExistence(timeout: 20))
        check.click()
        XCTAssertTrue(app.buttons["Push 39 Selected"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Push 39 Selected"].isEnabled)
    }

    func testPushingEveryImageShowsEachRowDone() {
        launch(scene: "shots-review")
        let pushAll = app.buttons["review.pushAll"]
        XCTAssertTrue(pushAll.waitForExistence(timeout: 20))
        pushAll.click()
        XCTAssertTrue(element("push.title").waitForExistence(timeout: 10))
        XCTAssertTrue(element("push.rateMeter").exists)
        let done = app.buttons["push.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 120))
        XCTAssertTrue(app.staticTexts["All 40 images pushed"].exists)
        done.click()
        XCTAssertTrue(element("review.sheet").waitForNonExistence(timeout: 5))
    }

    func testThePushInProgressCanCancelTheRest() {
        launch(scene: "shots-push")
        XCTAssertTrue(app.staticTexts["Pushing 40 images"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["15 of 40 done · reserve, upload and commit for each image"].waitForExistence(timeout: 60))
        XCTAssertTrue(app.buttons["push.cancelRemaining"].exists)
    }

    func testFailedImagesCanBeRetried() {
        launch(scene: "shots-push-partial")
        XCTAssertTrue(app.staticTexts["38 of 40 images pushed"].waitForExistence(timeout: 120))
        XCTAssertTrue(app.staticTexts["2 failed. Their live screenshots weren’t touched."].exists)
        let row = element("push.shots.row.zh-Hans.iPhone.1")
        let text = "\(row.label) \(row.value as? String ?? "")"
        XCTAssertTrue(text.contains("Upload timed out on part 2 of 3"), text)

        app.buttons["push.retryFailed"].click()
        XCTAssertTrue(app.staticTexts["All 40 images pushed"].waitForExistence(timeout: 60))
    }

    func testActivityRestoresAKeptSetThroughReview() {
        launch(scene: "shots-act")
        XCTAssertTrue(element("activity.sheet").waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Screenshots · 80 images in 8 locales"].exists)
        XCTAssertTrue(app.staticTexts["Kept on this Mac: the 3 sets this push replaced"].exists)
        app.buttons["activity.restoreScreenshots"].click()

        XCTAssertTrue(element("restore.sheet").waitForExistence(timeout: 10))
        element("restore.locale.de-DE").click()
        let queue = app.buttons["restore.queue"]
        XCTAssertTrue(queue.waitForExistence(timeout: 5))
        XCTAssertEqual(queue.label, "Queue 10 Screenshots for Review")
        queue.click()

        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 20))
        XCTAssertTrue(element("review.shots.item.de-DE.iPhone.1").waitForExistence(timeout: 20))
    }

    func testTheRestoreSceneOpensOnGerman() {
        launch(scene: "shots-act-restore")
        XCTAssertTrue(element("restore.sheet").waitForExistence(timeout: 20))
        let note = "Restoring takes German out of re-rendering until you choose Use Template Again, so the next push doesn’t replace these again."
        XCTAssertTrue(app.staticTexts[note].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Queue 10 Screenshots for Review"].exists)
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
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
