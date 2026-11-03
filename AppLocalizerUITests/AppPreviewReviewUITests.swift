//
//  AppPreviewReviewUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Board 29, driven through the DEBUG scenes in `StudioDebugPreviewReview`:
/// the plan's Music row, Watch the App Preview (play, quick asks, Ask
/// Claude Design, a revision, Approve), and the full-size viewer over the
/// new set and over Choose a direction. The scenes make real App Previews
/// on their first launch, so the player waits a little longer the first
/// time. Each test attaches the window's screenshot.
@MainActor
final class AppPreviewReviewUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Plan

    func testThePlanAsksForTheAppPreviewsMusic() {
        app.launch(debugScene: "st-plan-music")
        let music = element("autopilot.plan.music")
        XCTAssertTrue(music.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: element("autopilot.plan.musicNote")).hasPrefix("Required"), text(of: element("autopilot.plan.musicNote")))
        XCTAssertTrue(element("autopilot.plan.music.warm_acoustic").isSelected, "Warm acoustic unless the person picks another")
        let calm = element("autopilot.plan.music.calm_piano")
        calm.click()
        XCTAssertTrue(waitUntil { calm.isSelected })
        XCTAssertTrue(element("autopilot.plan.music.own_file").exists)
        attachScreenshot("Plan · Music")
    }

    // MARK: - Watch the App Preview

    func testWatchingPlaysTheAppPreviewThenApproveGoesOnToReviewAndPush() {
        app.launch(debugScene: "st-vid")
        XCTAssertTrue(element("autopilot.watch").waitForExistence(timeout: 20))
        for row in ["length", "size", "poster", "checks"] {
            XCTAssertTrue(element("autopilot.watch.info.\(row)").exists, row)
        }
        let play = app.buttons["appPreview.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil(timeout: 60) { play.isEnabled }, "The App Preview loads")
        play.click()
        XCTAssertTrue(waitUntil { play.label == "Pause" }, play.label)
        attachScreenshot("Watch · playing")
        play.click()
        XCTAssertTrue(waitUntil { play.label == "Play" }, play.label)

        let approve = app.buttons["autopilot.watch.approve"]
        XCTAssertTrue(approve.isEnabled)
        approve.click()
        XCTAssertTrue(element("autopilot.ready").waitForExistence(timeout: 10))
        attachScreenshot("Approved · Review & Push")
    }

    func testAQuickAskGoesToClaudeDesignAndApproveWaits() {
        app.launch(debugScene: "st-vid")
        let note = element("autopilot.watch.note")
        XCTAssertTrue(note.waitForExistence(timeout: 20))
        element("autopilot.watch.quick.Slower pace").click()
        element("autopilot.watch.quick.Start with Search").click()
        XCTAssertTrue(waitUntil { self.text(of: note) == "Slower pace, start with search" }, text(of: note))

        element("autopilot.watch.ask").click()
        let busy = element("autopilot.watch.busy")
        XCTAssertTrue(busy.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: busy).hasPrefix("Claude Design is revising “Slower pace, start with search”"), text(of: busy))
        XCTAssertFalse(app.buttons["autopilot.watch.approve"].isEnabled, "Approve waits for the new version")
        attachScreenshot("Watch · asked")
    }

    func testWhileClaudeDesignRevisesNothingElseCanChange() {
        app.launch(debugScene: "st-vid-busy")
        let busy = element("autopilot.watch.busy")
        XCTAssertTrue(busy.waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["autopilot.watch.approve"].isEnabled)
        XCTAssertFalse(element("autopilot.watch.quick.Bigger captions").isEnabled)
        XCTAssertFalse(element("autopilot.watch.ask").isEnabled)
        attachScreenshot("Watch · revising")
    }

    func testARevisionSaysWhatChanged() {
        app.launch(debugScene: "st-vid-rev")
        let revision = element("autopilot.watch.revision.2")
        XCTAssertTrue(revision.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: revision).contains("Slower pace, starts with Search"), text(of: revision))
        XCTAssertTrue(app.buttons["autopilot.watch.approve"].isEnabled)
        attachScreenshot("Watch · v2")
    }

    func testTheMusicMenuOffersTheLibraryAndTheOwnFile() {
        app.launch(debugScene: "st-vid")
        let music = element("autopilot.watch.music")
        XCTAssertTrue(music.waitForExistence(timeout: 20))
        music.click()
        XCTAssertTrue(app.menuItems["Calm piano"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.menuItems["Bright pop"].exists)
        XCTAssertTrue(app.menuItems["Your File…"].exists)
        attachScreenshot("Watch · music")
        app.typeKey(.escape, modifierFlags: [])
    }

    // MARK: - Full-size viewer

    func testTheViewerStepsThroughTheSetAndCloses() {
        app.launch(debugScene: "st-lb-shot")
        let viewer = element("studio.viewer")
        XCTAssertTrue(viewer.waitForExistence(timeout: 20))
        let count = element("studio.viewer.count")
        XCTAssertTrue(waitUntil { self.text(of: count) == "2 of 5" }, text(of: count))
        attachScreenshot("Viewer · screenshot 2")

        element("studio.viewer.next").click()
        XCTAssertTrue(waitUntil { self.text(of: count) == "3 of 5" }, text(of: count))
        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertTrue(waitUntil { self.text(of: count) == "4 of 5" }, text(of: count))
        app.typeKey(.leftArrow, modifierFlags: [])
        XCTAssertTrue(waitUntil { self.text(of: count) == "3 of 5" }, text(of: count))

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(waitUntil { !viewer.exists }, "Esc closes it")

        let first = element("studio.shot.0")
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.click()
        XCTAssertTrue(viewer.waitForExistence(timeout: 5), "A click on a screenshot opens it full size")
        XCTAssertTrue(waitUntil { self.text(of: count) == "1 of 5" }, text(of: count))
        XCTAssertFalse(element("studio.viewer.previous").isEnabled)
        element("studio.viewer.close").click()
        XCTAssertTrue(waitUntil { !viewer.exists })
    }

    func testTheHeaderOpensWithTheSearchArtwork() {
        app.launch(debugScene: "st-lb-header")
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 20))
        let title = element("studio.viewer.title")
        XCTAssertTrue(text(of: title).hasPrefix("Product page header"), text(of: title))
        XCTAssertEqual(text(of: element("studio.viewer.count")), "1 of 2")
        element("studio.viewer.next").click()
        XCTAssertTrue(waitUntil { self.text(of: title).hasPrefix("Search results") }, text(of: title))
        attachScreenshot("Viewer · search artwork")
    }

    func testTheAppPreviewPlaysFullSize() {
        app.launch(debugScene: "st-lb-video")
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: element("studio.viewer.title")).hasPrefix("App Preview"))
        let play = app.buttons["appPreview.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil(timeout: 60) { play.isEnabled }, "The App Preview loads")
        attachScreenshot("Viewer · App Preview")
    }

    func testADirectionsScreenshotOpensOverTheSheet() {
        app.launch(debugScene: "st-lb-dir")
        let viewer = element("studio.viewer")
        XCTAssertTrue(viewer.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: element("studio.viewer.subtitle")).hasPrefix("Direction from"), text(of: element("studio.viewer.subtitle")))
        attachScreenshot("Viewer · direction")
        element("studio.viewer.close").click()
        XCTAssertTrue(waitUntil { !viewer.exists })
        XCTAssertTrue(element("autopilot.sheet").exists, "The sheet stays open")
        // Each direction's row has its own thumbnails.
        let thumbnail = app.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnail.0").firstMatch
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 5))
        thumbnail.click()
        XCTAssertTrue(viewer.waitForExistence(timeout: 5), "A thumbnail opens it again")
        XCTAssertTrue(text(of: element("studio.viewer.count")).hasPrefix("1 of"), text(of: element("studio.viewer.count")))
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
