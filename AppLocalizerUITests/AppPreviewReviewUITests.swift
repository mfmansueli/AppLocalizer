//
//  AppPreviewReviewUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Board 29, driven through the DEBUG scenes in `StudioDebugPreviewReview`:
/// Look's App Preview music, the App Preview tab of Review & push while it's
/// watched (play, quick asks, Ask Claude Design, a revision, Approve), and
/// the full-size viewer over the new set and over Choose. The scenes make real App Previews
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

    // MARK: - Look

    func testLookAsksForTheAppPreviewsMusic() {
        app.launch(debugScene: "st-plan-music")
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        next.click()
        let row = element("autopilot.guided.look.musicRow")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        reveal(row)
        let required = NSPredicate(format: "value BEGINSWITH %@ OR label BEGINSWITH %@", "Required", "Required")
        XCTAssertTrue(row.staticTexts.matching(required).firstMatch.exists, "Every App Preview has music")
        XCTAssertTrue(element("autopilot.guided.look.music.warm_acoustic").isSelected, "Warm acoustic unless the person picks another")
        let calm = element("autopilot.guided.look.music.calm_piano")
        calm.click()
        XCTAssertTrue(waitUntil { calm.isSelected })
        XCTAssertTrue(element("autopilot.guided.look.music.own_file").exists)
        attachScreenshot("Look · App Preview music")
    }

    func testLookOffersTheOtherMoodsInAMenu() {
        app.launch(debugScene: "st-plan-music")
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        next.click()
        let more = element("autopilot.guided.look.musicMore")
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        reveal(more)
        more.click()
        let ambient = app.menuItems["Soft ambient"]
        XCTAssertTrue(ambient.waitForExistence(timeout: 5))
        XCTAssertTrue(app.menuItems["Playful marimba"].exists)
        ambient.click()
        let warm = element("autopilot.guided.look.music.warm_acoustic")
        XCTAssertTrue(waitUntil { !warm.isSelected }, "The mood from the menu replaces the featured track")
        attachScreenshot("Look · a mood from the menu")
    }

    // MARK: - Watch the App Preview

    func testWatchingPlaysTheAppPreviewThenApproveMakesItFinal() {
        app.launch(debugScene: "st-vid")
        showTheAppPreview()
        for row in ["length", "size", "poster", "checks"] {
            XCTAssertTrue(element("autopilot.watch.info.\(row)").exists, row)
        }
        let play = app.buttons["appPreview.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil(timeout: 60) { play.isEnabled }, "The App Preview loads")
        // The controls sit under the video, below the footer until the
        // step scrolls.
        reveal(play)
        play.click()
        XCTAssertTrue(waitUntil { play.label == "Pause" }, play.label)
        attachScreenshot("Watch · playing")
        play.click()
        XCTAssertTrue(waitUntil { play.label == "Play" }, play.label)

        let approve = app.buttons["autopilot.guided.review.approve"]
        XCTAssertTrue(approve.isEnabled)
        XCTAssertEqual(approve.label, "Approve App Preview")
        approve.click()
        // On to the screenshots, the part still to approve.
        let tab = element("autopilot.guided.review.tabs.appPreview")
        XCTAssertTrue(waitUntil { tab.label == "✓ App Preview" }, tab.label)
        tab.click()
        XCTAssertTrue(waitUntil { approve.isSelected }, "Approved")
        XCTAssertFalse(element("autopilot.watch.askBox").exists, "Approved, it's final: nothing more to ask")
        attachScreenshot("Approved · Review & push")
    }

    func testAQuickAskGoesToClaudeDesignAndApproveWaits() {
        app.launch(debugScene: "st-vid")
        showTheAppPreview()
        let note = element("autopilot.watch.note")
        XCTAssertTrue(note.waitForExistence(timeout: 20))
        element("autopilot.watch.quick.Slower pace").click()
        element("autopilot.watch.quick.Start with Search").click()
        XCTAssertTrue(waitUntil { self.text(of: note) == "Slower pace, start with search" }, text(of: note))

        element("autopilot.watch.ask").click()
        let busy = element("autopilot.watch.busy")
        XCTAssertTrue(busy.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: busy).hasPrefix("Claude Design is revising “Slower pace, start with search”"), text(of: busy))
        XCTAssertFalse(app.buttons["autopilot.guided.review.approve"].isEnabled, "Approve waits for the new version")
        attachScreenshot("Watch · asked")
    }

    func testWhileClaudeDesignRevisesNothingElseCanChange() {
        app.launch(debugScene: "st-vid-busy")
        showTheAppPreview()
        let busy = element("autopilot.watch.busy")
        XCTAssertTrue(busy.waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["autopilot.guided.review.approve"].isEnabled)
        XCTAssertFalse(element("autopilot.watch.quick.Bigger captions").isEnabled)
        XCTAssertFalse(element("autopilot.watch.ask").isEnabled)
        attachScreenshot("Watch · revising")
    }

    func testARevisionSaysWhatChanged() {
        app.launch(debugScene: "st-vid-rev")
        showTheAppPreview()
        let revision = element("autopilot.watch.revision.2")
        XCTAssertTrue(revision.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: revision).contains("Slower pace, starts with Search"), text(of: revision))
        XCTAssertTrue(app.buttons["autopilot.guided.review.approve"].isEnabled)
        attachScreenshot("Watch · v2")
    }

    func testTheMusicMenuOffersTheLibraryAndTheOwnFile() {
        app.launch(debugScene: "st-vid")
        showTheAppPreview()
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
        XCTAssertTrue(element("autopilot.guided.sheet").exists, "The sheet stays open")
        // Each direction's row has its own thumbnails.
        let thumbnail = app.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnail.0").firstMatch
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 5))
        thumbnail.click()
        XCTAssertTrue(viewer.waitForExistence(timeout: 5), "A thumbnail opens it again")
        XCTAssertTrue(text(of: element("studio.viewer.count")).hasPrefix("1 of"), text(of: element("studio.viewer.count")))
    }

    // MARK: - Helpers

    /// Review & push opens on the first part not approved, the
    /// screenshots: its App Preview tab, once the App Preview is made.
    private func showTheAppPreview() {
        XCTAssertTrue(element("autopilot.guided.review").waitForExistence(timeout: 20))
        let tab = element("autopilot.guided.review.tabs.appPreview")
        if tab.exists { tab.click() }
        XCTAssertTrue(element("autopilot.guided.review.appPreview").waitForExistence(timeout: 60), "The App Preview loads")
    }

    /// Scrolls the guided sheet's step until `target` is inside what it
    /// shows, above the footer: the step scrolls under it, so a click on
    /// what's below lands on the footer.
    private func reveal(_ target: XCUIElement) {
        let step = element("autopilot.guided.sheet").scrollViews.firstMatch
        guard step.waitForExistence(timeout: 5), target.waitForExistence(timeout: 5) else { return }
        let footer = element("autopilot.guided.footer.text")
        var tries = 0
        while tries < 12 {
            let bottom = min(step.frame.maxY, footer.exists ? footer.frame.minY - 12 : step.frame.maxY)
            if target.frame.minY >= step.frame.minY, target.frame.maxY <= bottom { return }
            step.scroll(byDeltaX: 0, deltaY: target.frame.minY < step.frame.minY ? 200 : -200)
            tries += 1
        }
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
