//
//  ArtworkMotionUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Header and search, still or motion (board 32), on
/// `StudioDebugArtMotion`'s scenes: the plan's still/motion and "what it
/// shows" rows with their notes, the expected result box, the brief the
/// Design step shows, and a loop full size with Show iPhone Area.
@MainActor
final class ArtworkMotionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testStillOrMotionAndWhatTheArtworkShows() {
        app.launch(debugScene: "st-plan-motion")
        let motion = element("autopilot.plan.artworkMotionNote")
        XCTAssertTrue(motion.waitForExistence(timeout: 20))
        reveal(motion)
        XCTAssertTrue(element("autopilot.plan.artworkMotion.loop").isSelected)
        let loop = "Claude Design animates its artwork into a 20-second silent loop: slow light and scene, a gentle float of the phone"
        XCTAssertTrue(text(of: motion).hasPrefix(loop), text(of: motion))
        attachScreenshot("Plan · motion loop")

        tap("autopilot.plan.artworkShows.scene")
        let shows = element("autopilot.plan.artworkShowsNote")
        XCTAssertTrue(waitUntil { self.text(of: shows).hasPrefix("Only the name, the headline and a scene in the brand’s style.") }, text(of: shows))
        XCTAssertFalse(text(of: motion).contains("float"), "A scene has nothing to float")

        tap("autopilot.plan.artworkMotion.still")
        XCTAssertTrue(waitUntil { !self.text(of: motion).contains("20-second") }, text(of: motion))
        attachScreenshot("Plan · still scene")
    }

    /// Each note sits under its choice, across the row, rather than in a
    /// narrow column beside it, where the scene's note wrapped every few
    /// words.
    func testTheNotesSitUnderTheirChoices() {
        app.launch(debugScene: "st-plan-art-custom")
        let shows = element("autopilot.plan.artworkShows")
        let showsNote = element("autopilot.plan.artworkShowsNote")
        XCTAssertTrue(showsNote.waitForExistence(timeout: 20))
        reveal(showsNote)
        XCTAssertGreaterThanOrEqual(showsNote.frame.minY, shows.frame.maxY, "The note is under the choice")
        XCTAssertGreaterThan(showsNote.frame.width, shows.frame.width, "The note spans the row, wider than the choice")
        XCTAssertLessThan(showsNote.frame.height, 50, "Two lines at most, not one word a line: \(showsNote.frame)")

        let motion = element("autopilot.plan.artworkMotion")
        let motionNote = element("autopilot.plan.artworkMotionNote")
        XCTAssertGreaterThanOrEqual(motionNote.frame.minY, motion.frame.maxY)
        attachScreenshot("Plan · notes under their choices")
    }

    func testTheExpectedResultIsInThePlanAndTheBrief() {
        app.launch(debugScene: "st-plan-art-custom")
        let box = element("autopilot.plan.artworkDirection.text")
        XCTAssertTrue(box.waitForExistence(timeout: 20))
        reveal(box)
        XCTAssertTrue(text(of: box).hasPrefix("A calm night sky over hills"), text(of: box))
        attachScreenshot("Plan · expected result")

        app.terminate()
        app.launch(debugScene: "st-des-art-custom")
        let brief = element("autopilot.design.artworkBrief")
        XCTAssertTrue(brief.waitForExistence(timeout: 20))
        let words = brief.descendants(matching: .staticText).allElementsBoundByIndex.map { text(of: $0) }.joined(separator: " ")
        XCTAssertTrue(words.contains("Motion · 20-second loop"), words)
        XCTAssertTrue(words.contains("Your direction"), words)
        XCTAssertTrue(words.contains("Safe area"), words)
        attachScreenshot("Design · artwork brief")
    }

    func testALoopOpensFullSizeWithTheIPhoneArea() {
        app.launch(debugScene: "st-lb-header-guide")
        let title = element("studio.viewer.title")
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        XCTAssertTrue(waitUntil(timeout: 15) { self.text(of: title).hasSuffix(" · motion") }, text(of: title))
        XCTAssertTrue(text(of: element("studio.viewer.subtitle")).hasPrefix("20-second loop · plays muted on repeat · "))
        XCTAssertEqual(element("studio.viewer.action").label, "Hide iPhone Area", "Show iPhone Area is on")
        attachScreenshot("Viewer · header loop with the iPhone area")
    }

    // MARK: - Helpers

    /// Scrolls the plan until `target` is inside what it shows.
    private func reveal(_ target: XCUIElement) {
        let plan = element("autopilot.plan")
        var tries = 0
        while !(target.frame.minY >= plan.frame.minY && target.frame.maxY <= plan.frame.maxY), tries < 12 {
            plan.scroll(byDeltaX: 0, deltaY: target.frame.minY < plan.frame.minY ? 200 : -200)
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
