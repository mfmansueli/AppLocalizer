//
//  AutopilotGuidedPushUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The guided Autopilot's last steps, on `StudioDebugGuided`'s scenes:
/// Review & push (every part approved before Push to App Store…, which
/// hands the upload to Review & Push) and Sent. Each test attaches the
/// window's screenshot.
@MainActor
final class AutopilotGuidedPushUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testPushWaitsForEveryPart() {
        app.launch(debugScene: "ap-review")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.waitForExistence(timeout: 20))
        let push = element("autopilot.guided.push")
        XCTAssertFalse(push.isEnabled)
        attachScreenshot("Review · screenshots")

        for _ in 0..<3 {
            approve.click()
            RunLoop.current.run(until: .now.addingTimeInterval(0.5))
        }
        XCTAssertTrue(waitUntil { push.isEnabled }, "Everything approved")
        push.click()
        XCTAssertTrue(element("autopilot.guided.push.confirm").waitForExistence(timeout: 5))
        attachScreenshot("Review · push?")
    }

    /// A push that starts closes Autopilot for Review & Push; one that
    /// can't (this scene has no App Store Connect to push to) keeps
    /// Autopilot open and says why.
    func testAPushThatCantStartStaysInAutopilot() {
        app.launch(debugScene: "ap-review")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.waitForExistence(timeout: 20))
        let push = element("autopilot.guided.push")
        for _ in 0..<3 {
            approve.click()
            RunLoop.current.run(until: .now.addingTimeInterval(0.5))
        }
        XCTAssertTrue(waitUntil { push.isEnabled }, "Everything approved")
        push.click()
        let confirm = element("autopilot.guided.push.confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.click()
        XCTAssertTrue(app.staticTexts["Couldn’t push"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("autopilot.guided.sheet").exists)
        XCTAssertFalse(element("review.sheet").exists)
    }

    func testTheHeaderTabFollowsTheApprovedScreenshots() {
        app.launch(debugScene: "ap-review-art")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.waitForExistence(timeout: 20))
        XCTAssertEqual(approve.label, "Approve Header and Search")
        attachScreenshot("Review · header and search")
    }

    func testSentSaysWhatWasSent() {
        app.launch(debugScene: "ap-done")
        let title = element("autopilot.guided.done.title")
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: title), "Sent to the App Store")
        XCTAssertTrue(text(of: element("autopilot.guided.done.text")).contains("are on App Store Connect."))
        XCTAssertFalse(element("autopilot.guided.push").exists, "No footer once it's sent")
        attachScreenshot("Sent")
    }

    // MARK: - Helpers

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        return condition()
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
