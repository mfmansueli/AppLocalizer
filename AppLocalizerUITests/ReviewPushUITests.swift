//
//  ReviewPushUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Review & Push and Activity, driven through the DEBUG scenes in
/// `ReviewPushDebugScenes` (simulated App Store Connect, nothing leaves the Mac).
@MainActor
final class ReviewPushUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testReviewGroupsChangesAndFiltersBySource() {
        launch(scene: "review")
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 10))
        XCTAssertTrue(element("review.row.price.6450100002.BRA").exists)
        XCTAssertTrue(app.staticTexts["Subscription Pricing · Lumen Plus Annual"].exists)

        element("review.sourceFilter").radioButtons["Machine translation 2"].click()
        XCTAssertTrue(element("review.row.price.6450100002.BRA").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Push 2 Changes"].exists)
    }

    func testAllAppsShowsEveryAppsChanges() {
        launch(scene: "review")
        XCTAssertTrue(element("review.scope").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["28 changes"].exists)
        element("review.scope").radioButtons["All apps · 31"].click()
        XCTAssertTrue(app.staticTexts["31 changes"].waitForExistence(timeout: 5))
    }

    func testDiscardingARowRemovesIt() {
        launch(scene: "review")
        let discard = app.buttons["review.discard.price.6450100002.CAN"]
        XCTAssertTrue(discard.waitForExistence(timeout: 10))
        discard.click()
        XCTAssertTrue(element("review.row.price.6450100002.CAN").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Push 27 Changes"].exists)
    }

    func testPushingShowsProgressAndEmptiesTheQueue() {
        launch(scene: "review")
        let pushAll = app.buttons["review.pushAll"]
        XCTAssertTrue(pushAll.waitForExistence(timeout: 10))
        pushAll.click()
        XCTAssertTrue(element("push.title").waitForExistence(timeout: 5))
        XCTAssertTrue(element("push.rateMeter").exists)
        let done = app.buttons["push.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["28 pushed"].exists)
        done.click()
        XCTAssertTrue(element("review.sheet").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["overview.pendingChangesCard"].waitForExistence(timeout: 5))
    }

    func testPartialFailureShowsApplesErrorAndOffersRetry() {
        launch(scene: "push-partial")
        XCTAssertTrue(app.staticTexts["24 pushed · 2 failed"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["push.retryFailed"].exists)
        XCTAssertTrue(app.buttons["push.viewResults"].exists)
        let chile = element("push.row.price.6450100002.CHL")
        let chileText = "\(chile.label) \(chile.value as? String ?? "")"
        XCTAssertTrue(chileText.contains("ENTITY_ERROR.RELATIONSHIP.INVALID"), chileText)

        app.buttons["push.done"].click()
        XCTAssertTrue(element("workspace.banner").waitForExistence(timeout: 5))
        app.buttons["banner.reviewFailed"].click()
        XCTAssertTrue(element("review.row.price.6450100002.CHL").waitForExistence(timeout: 5))
    }

    func testConflictMustBeResolvedBeforePushing() {
        launch(scene: "push-conflict")
        XCTAssertTrue(app.buttons["Push 3 Changes"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["4 changes · 1 needs attention"].exists)
        app.buttons["review.keepMine"].click()
        XCTAssertTrue(app.buttons["Push 4 Changes"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["review.keepMine"].exists)
    }

    func testAssistantConflictAndRejectAll() {
        launch(scene: "review-assistant")
        let pickAssistant = app.buttons["review.pickAssistant"]
        XCTAssertTrue(pickAssistant.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Push 10 Changes"].exists)

        app.buttons["review.rejectAll"].click()
        XCTAssertTrue(pickAssistant.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Push 1 Change"].exists)
    }

    func testEmptyQueueSaysSo() {
        launch(scene: "review-empty")
        XCTAssertTrue(app.staticTexts["Nothing to push"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["review.pushAll"].isEnabled)
    }

    func testActivityRestoresPreviousValuesThroughReview() {
        launch(scene: "activity")
        XCTAssertTrue(element("activity.sheet").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Subscription Pricing · Mexico, Türkiye, India"].exists)
        app.buttons.matching(identifier: "activity.restore").element(boundBy: 2).click()
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 5))
        XCTAssertTrue(element("review.row.price.6450100002.MEX").exists)
        XCTAssertTrue(app.staticTexts["Restore"].exists)
    }

    func testOfflineBanner() {
        launch(scene: "banner-offline")
        XCTAssertTrue(element("workspace.banner").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["You're offline"].exists)
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
