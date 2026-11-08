//
//  AutopilotPickUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Pick the best captures (board 31), on the DEBUG scenes in
/// `StudioDebugPick`: another attempt becomes your pick, the recording's
/// moments make the App Preview's length, Use These Picks waits outside
/// Apple's 15–30 s, and Record Again says what happens next. Each test
/// attaches the sheet's screenshot.
@MainActor
final class AutopilotPickUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testAnotherAttemptBecomesYourPick() {
        app.launch(debugScene: "st-pick-shots-video")
        let badge = element("autopilot.pick.badge.1")
        XCTAssertTrue(badge.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: badge), "Claude Code’s pick")
        XCTAssertTrue(text(of: element("autopilot.guided.footer.text")).hasPrefix("Claude Code’s picks are selected · App Preview: 3 moments"))
        attachScreenshot("Pick · Claude Code’s picks")

        // An attempt opens full size, where Use This Capture picks it.
        let second = element("autopilot.pick.attempt.1.2")
        XCTAssertTrue(second.exists)
        reveal(second)
        second.click()
        let use = element("studio.viewer.action")
        XCTAssertTrue(use.waitForExistence(timeout: 5))
        XCTAssertEqual(use.label, "Use This Capture")
        use.click()
        XCTAssertTrue(waitUntil { use.label == "✓ Used for Week" }, use.label)
        element("studio.viewer.close").click()
        XCTAssertTrue(waitUntil { self.text(of: badge) == "Your pick" }, text(of: badge))
        XCTAssertTrue(text(of: element("autopilot.pick.reason.1")).hasPrefix("⚠︎ Ranked lower:"))
        XCTAssertTrue(text(of: element("autopilot.guided.footer.text")).hasPrefix("1 pick changed by you; the rest are Claude Code’s"))
        XCTAssertTrue(app.buttons["autopilot.guided.usePicks"].isEnabled)
        attachScreenshot("Pick · your pick")
    }

    /// Six seconds a moment and the end card: five moments are 0:36, so
    /// Use These Picks waits until one comes out.
    func testUseThesePicksWaitsOutsideFifteenToThirtySeconds() {
        app.launch(debugScene: "st-pick-rec")
        let summary = element("autopilot.recording.summary")
        XCTAssertTrue(summary.waitForExistence(timeout: 30))
        XCTAssertTrue(text(of: summary).hasSuffix("· 0:24 · within Apple’s 15–30 s"), text(of: summary))
        let use = app.buttons["autopilot.guided.usePicks"]
        XCTAssertTrue(use.isEnabled)

        tap("autopilot.moment.use.3")
        XCTAssertTrue(waitUntil { self.text(of: summary).hasSuffix("· 0:30 · within Apple’s 15–30 s") }, text(of: summary))
        tap("autopilot.moment.use.4")
        XCTAssertTrue(waitUntil { self.text(of: summary).hasSuffix("· 0:36 · over Apple’s 30 s: remove a moment") }, text(of: summary))
        XCTAssertTrue(waitUntil { !use.isEnabled }, "Use These Picks waits")
        attachScreenshot("Pick · over 30 s")

        tap("autopilot.moment.use.0")
        XCTAssertTrue(waitUntil { use.isEnabled })
        XCTAssertTrue(text(of: element("autopilot.guided.footer.text")).hasSuffix("App Preview: 4 moments + end card, 0:30."))
    }

    func testRecordAgainSaysWhatHappensNext() {
        app.launch(debugScene: "st-pick-rec")
        let again = element("autopilot.moment.recordAgain.1")
        XCTAssertTrue(again.waitForExistence(timeout: 30))
        XCTAssertFalse(element("autopilot.moment.recordAgainNote.1").exists)
        reveal(again)
        again.click()
        let note = element("autopilot.moment.recordAgainNote.1")
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: note), "Claude Code will record “Week” again before the design step. The rest of the recording stays.")
        attachScreenshot("Pick · record again")
    }

    func testIPhoneDuoShowsBothDisplays() {
        app.launch(debugScene: "st-pick-duo")
        let card = element("autopilot.pick.duo.0")
        XCTAssertTrue(card.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: element("autopilot.pick.note")), "Same moments as iPhone, on the inner and cover displays. Click to see them full size.")
        attachScreenshot("Pick · iPhone Duo")
    }

    // MARK: - Helpers

    /// Scrolls Pick until `target` is inside what it shows.
    private func reveal(_ target: XCUIElement) {
        let pick = element("autopilot.pick")
        var tries = 0
        while !(target.frame.minY >= pick.frame.minY && target.frame.maxY <= pick.frame.maxY), tries < 12 {
            pick.scroll(byDeltaX: 0, deltaY: target.frame.minY < pick.frame.minY ? 200 : -200)
            tries += 1
        }
    }

    private func tap(_ identifier: String) {
        let target = element(identifier)
        reveal(target)
        target.click()
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

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
