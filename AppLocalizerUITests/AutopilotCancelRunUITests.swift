//
//  AutopilotCancelRunUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Cancel Run… after Capture (`st-des-revise-motion`, at Design): it asks
/// first; Keep Going stays, Cancel Run goes back to the plan.
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

    func testCancelRunAsksThenGoesBackToThePlan() {
        app.launch(debugScene: "st-des-revise-motion")
        XCTAssertTrue(element("autopilot.design").waitForExistence(timeout: 20))
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
        XCTAssertTrue(element("autopilot.design").waitForExistence(timeout: 5), "Keep Going stays at Design")

        cancel.click()
        let confirm = app.buttons["Cancel Run"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.click()
        XCTAssertTrue(element("autopilot.start").waitForExistence(timeout: 10), "Back at the plan")
        attachScreenshot("Cancel Run · back at the plan")
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
