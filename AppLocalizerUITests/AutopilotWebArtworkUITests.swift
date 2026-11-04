//
//  AutopilotWebArtworkUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The header and search Claude Design designed as HTML pages: Choose shows
/// each direction's own (three different images, not one layout
/// recolored) and says Claude Design made them, and full size a loop plays
/// live from the page's CSS, pauses, and follows the scrubber. Each test
/// attaches the window's screenshot.
@MainActor
final class AutopilotWebArtworkUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testChooseShowsEachDirectionsOwnPages() {
        app.launch(debugScene: "st-choose-web-artwork")
        let subtitle = element("autopilot.choose.subtitle")
        XCTAssertTrue(subtitle.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: subtitle).contains("the header and search images are designed by Claude Design itself"), text(of: subtitle))

        let headers = app.descendants(matching: .any).matching(identifier: "autopilot.direction.extra.0")
        XCTAssertTrue(headers.element(boundBy: 2).waitForExistence(timeout: 10), "Three directions, each with its header")
        // Rendered by WebKit one by one: wait until the three differ.
        XCTAssertTrue(waitUntil(timeout: 30) {
            let images = (0..<3).map { headers.element(boundBy: $0).screenshot().pngRepresentation }
            return Set(images).count == 3
        }, "Each direction's header is its own page")
        let searches = app.descendants(matching: .any).matching(identifier: "autopilot.direction.extra.1")
        XCTAssertTrue(waitUntil(timeout: 30) {
            Set((0..<3).map { searches.element(boundBy: $0).screenshot().pngRepresentation }).count == 3
        }, "And its search image")
        attachScreenshot("Choose · Claude Design's own header and search")
    }

    func testAPagesLoopPlaysLiveAndPauses() {
        app.launch(debugScene: "st-lb-web-loop")
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 20))
        // The player's container merges into the viewer's (the outer
        // identifier wins), so it's found by its Play or Pause button and
        // watched through the viewer, where nothing else moves.
        let play = app.buttons["artwork.loop.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 20), "The header's loop plays in the viewer")
        XCTAssertEqual(play.label, "Pause the loop")
        // The stars twinkle and the moon glows: the frames change. Only the
        // image is compared: the time under it moves too.
        RunLoop.current.run(until: .now.addingTimeInterval(2))
        let first = image(above: play)
        XCTAssertTrue(waitUntil(timeout: 5) { self.image(above: play) != first }, "The page's CSS motion plays")
        attachScreenshot("Viewer · Claude Design's header loop playing")

        play.click()
        XCTAssertTrue(waitUntil { play.label == "Play the loop" })
        RunLoop.current.run(until: .now.addingTimeInterval(0.5))
        let paused = image(above: play)
        RunLoop.current.run(until: .now.addingTimeInterval(1.5))
        XCTAssertEqual(image(above: play), paused, "Paused, it stays put")

        // Dragged elsewhere, the page shows that moment, and stays paused.
        let time = element("artwork.loop.time")
        element("artwork.loop.scrubber").coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.5)).click()
        XCTAssertTrue(waitUntil { self.text(of: time).hasPrefix("0:10") }, text(of: time))
        XCTAssertTrue(waitUntil(timeout: 5) { self.image(above: play) != paused }, "The page seeks with the scrubber")
        XCTAssertEqual(play.label, "Play the loop")
        attachScreenshot("Viewer · Claude Design's header loop moved to 0:10")
    }

    /// The viewer's screenshot above `controls`: the image alone.
    private func image(above controls: XCUIElement) -> Data {
        let viewer = element("studio.viewer")
        let shot = viewer.screenshot().image
        guard let image = shot.cgImage(forProposedRect: nil, context: nil, hints: nil), viewer.frame.width > 0 else { return Data() }
        let scale = CGFloat(image.width) / viewer.frame.width
        let height = max(1, (controls.frame.minY - viewer.frame.minY - 14) * scale)
        guard let cropped = image.cropping(to: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: height)) else { return Data() }
        return NSBitmapImageRep(cgImage: cropped).representation(using: .png, properties: [:]) ?? Data()
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
            RunLoop.current.run(until: .now.addingTimeInterval(0.3))
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
