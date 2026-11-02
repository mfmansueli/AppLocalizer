//
//  AutopilotContinuationUITests.swift
//  AppLocalizerUITests
//

import AppKit
import XCTest

/// A Screenshot Autopilot run nobody works on any more says so, with
/// Continue; one that's going doesn't. The DEBUG scenes have no helper, so
/// Continue copies the prompt that picks the run up.
@MainActor
final class AutopilotContinuationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testARunNothingArrivesForSaysSoAndContinues() {
        app.launch(debugScene: "st-stalled")
        let notice = element("autopilot.stall")
        XCTAssertTrue(notice.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: element("autopilot.stall.text")).contains("Nothing has arrived for 85 minutes"), text(of: element("autopilot.stall.text")))
        let stage = element("autopilot.stage.capture")
        XCTAssertTrue(stage.label.contains("Nothing new for a while"), stage.label)
        XCTAssertTrue(text(of: element("autopilot.footer.text")).contains("44 captures left"), text(of: element("autopilot.footer.text")))
        XCTAssertTrue(app.buttons["autopilot.continue"].exists)

        app.buttons["autopilot.stall.continue"].click()
        let note = element("autopilot.stall.note")
        XCTAssertTrue(wait(until: { self.text(of: note).hasPrefix("Copied.") }, timeout: 5), text(of: note))
        let copied = NSPasteboard.general.string(forType: .string) ?? ""
        XCTAssertTrue(copied.hasPrefix("Continue Lumen Journal’s screenshot run from AppLocalizer"), copied)
    }

    func testARunThatsGoingSaysNothing() {
        app.launch(debugScene: "st-cap")
        XCTAssertTrue(element("autopilot.capture").waitForExistence(timeout: 15))
        XCTAssertFalse(element("autopilot.stall").exists)
        XCTAssertFalse(app.buttons["autopilot.continue"].exists)
        XCTAssertFalse(element("autopilot.stage.capture").label.contains("stopped"))
    }

    private func wait(until condition: @escaping () -> Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.25))
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
