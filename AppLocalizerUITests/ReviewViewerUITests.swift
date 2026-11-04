//
//  ReviewViewerUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Review & Push's full-size viewer, through the DEBUG scenes: a click on
/// a screenshot opens its set large, ← → step through the slots, Live Now |
/// New (and ↑ ↓) compare a slot's sides, a double-click zooms and Fit goes
/// back, an App Preview plays, and Esc closes the viewer, not the sheet.
@MainActor
final class ReviewViewerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testAScreenshotOpensLargeAndComparesItsSides() {
        app.launch(debugScene: "shots-review")
        let open = app.buttons["review.shots.open.ar-SA.iPhone.1.new"]
        XCTAssertTrue(open.waitForExistence(timeout: 20))
        open.click()

        let viewer = element("review.viewer")
        XCTAssertTrue(viewer.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("review.viewer.title")).contains("Arabic · iPhone · 1"), text(of: element("review.viewer.title")))
        XCTAssertTrue(text(of: element("review.viewer.subtitle")).contains("New"), text(of: element("review.viewer.subtitle")))
        XCTAssertTrue(text(of: element("review.viewer.count")).contains("1 of"), text(of: element("review.viewer.count")))
        attach("Screenshot, new side")

        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertTrue(text(of: element("review.viewer.count")).contains("2 of"), "→ steps to the next slot")

        element("review.viewer.side").radioButtons["Live Now"].click()
        let live = text(of: element("review.viewer.subtitle"))
        XCTAssertTrue(live.contains("Live now") || live.contains("Nothing live"), live)
        attach("Screenshot, live side")

        app.typeKey(.downArrow, modifierFlags: [])
        XCTAssertTrue(text(of: element("review.viewer.subtitle")).contains("New"), "↓ flips back to the new side")

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(viewer.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("review.sheet").exists, "Esc closes the viewer, not Review & Push")
    }

    func testADoubleClickZoomsAndFitGoesBack() {
        app.launch(debugScene: "shots-review-extras")
        let open = app.buttons["review.extras.open.header-en-US"]
        XCTAssertTrue(open.waitForExistence(timeout: 30))
        scrollReview(by: -400, until: open)
        open.click()

        let zoom = element("review.viewer.zoom")
        XCTAssertTrue(zoom.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("review.viewer.title")).contains("English (U.S.) · Header 21:9"))
        XCTAssertFalse(element("review.viewer.zoom.percent").exists, "It opens at fit")

        zoom.doubleClick()
        let percent = element("review.viewer.zoom.percent")
        XCTAssertTrue(percent.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: percent).contains("200%"), text(of: percent))
        attach("Header zoomed")

        app.buttons["review.viewer.zoom.fit"].click()
        XCTAssertTrue(percent.waitForNonExistence(timeout: 5))
    }

    func testAnAppPreviewPlaysInTheViewer() {
        app.launch(debugScene: "shots-review-extras")
        let open = app.buttons["review.extras.open.iphone-en-US"]
        XCTAssertTrue(open.waitForExistence(timeout: 30))
        scrollReview(by: -400, until: open)
        open.click()

        XCTAssertTrue(element("review.viewer").waitForExistence(timeout: 5))
        let play = app.buttons["appPreview.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        // The scene writes a real movie in the background.
        expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 30)
        play.click()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        attach("App Preview playing")

        app.typeKey(.space, modifierFlags: [])
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5), "Space pauses it")

        app.buttons["review.viewer.close"].click()
        XCTAssertTrue(element("review.viewer").waitForNonExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        "\(element.label) \(element.value as? String ?? "")"
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
