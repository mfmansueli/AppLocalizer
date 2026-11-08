//
//  AutopilotCancelRunUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Cancel Run… after Capture (`st-des-revise-motion`, at Making it while
/// the looks are designed): it asks first; Keep Going stays, Cancel Run
/// goes back to the setup steps.
@MainActor
final class AutopilotCancelRunUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testCancelRunAsksThenGoesBackToTheSetup() {
        app.launch(debugScene: "st-des-revise-motion")
        let making = element("autopilot.guided.making.steps")
        XCTAssertTrue(making.waitForExistence(timeout: 20))
        let cancel = element("autopilot.cancelRun.later")
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))

        cancel.click()
        let keep = app.buttons["Keep Going"]
        XCTAssertTrue(keep.waitForExistence(timeout: 5), "It asks first")
        let nothingSent = "Nothing was sent to App Store Connect"
        let says = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", nothingSent, nothingSent)
        XCTAssertTrue(app.staticTexts.matching(says).firstMatch.exists, "It says nothing was pushed")
        attachScreenshot("Cancel Run · the question")
        keep.click()
        XCTAssertTrue(making.waitForExistence(timeout: 5), "Keep Going stays at Making it")

        cancel.click()
        let confirm = app.buttons["Cancel Run"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.click()
        // The setup step the run was started from: What to make in the
        // scene, the plan after a real Start.
        XCTAssertTrue(waitUntil(timeout: 10) {
            self.element("autopilot.guided.next").exists || self.element("autopilot.guided.start").exists
        }, "Back at the setup steps")
        XCTAssertFalse(cancel.exists)
        attachScreenshot("Cancel Run · back at the setup")
    }

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

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
