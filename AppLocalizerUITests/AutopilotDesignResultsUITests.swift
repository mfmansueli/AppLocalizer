//
//  AutopilotDesignResultsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Design with its results (`st-des-revise-motion`: the three directions on
/// every device, header and search loops and an App Preview, while Claude
/// Code makes the person's note): the cards fit the sheet, and a click
/// opens a screenshot, the artwork (its loop plays and pauses) or the
/// recording full size, like Choose and the Studio. Each test attaches the
/// window's screenshot.
@MainActor
final class AutopilotDesignResultsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testTheCardsFitTheSheet() {
        launchDesign()
        XCTAssertTrue(element("autopilot.design.revision").exists)
        let sheet = element("autopilot.sheet").frame.insetBy(dx: -1, dy: -1)
        let stage = element("autopilot.stage.design").frame
        XCTAssertGreaterThanOrEqual(stage.minX, sheet.minX, "The stage list is cut at \(stage) in \(sheet)")
        for index in 0..<3 {
            let card = element("autopilot.design.direction.\(index)")
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            XCTAssertTrue(sheet.minX <= card.frame.minX && card.frame.maxX <= sheet.maxX, "Card \(index) at \(card.frame) spills out of \(sheet)")
            for identifier in ["autopilot.direction.thumbnails", "autopilot.direction.extras"] {
                let part = card.descendants(matching: .any).matching(identifier: identifier).firstMatch
                XCTAssertTrue(part.exists, "Card \(index) has \(identifier)")
                let inside = card.frame.insetBy(dx: -1, dy: -1)
                XCTAssertTrue(inside.minX <= part.frame.minX && part.frame.maxX <= inside.maxX, "\(identifier) at \(part.frame) spills out of card \(index) at \(card.frame)")
            }
        }
        attachScreenshot("Design · results fit")
    }

    func testAScreenshotOpensFullSize() {
        launchDesign()
        let card = element("autopilot.design.direction.1")
        card.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnail.2").firstMatch.click()
        let viewer = element("studio.viewer")
        XCTAssertTrue(viewer.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("studio.viewer.title")).hasPrefix("Full Bleed · 3"), text(of: element("studio.viewer.title")))
        attachScreenshot("Design · screenshot full size")
        element("studio.viewer.close").click()
        XCTAssertTrue(waitUntil { !viewer.exists })
        XCTAssertTrue(element("autopilot.design").exists, "Design stays open")
    }

    func testTheHeaderLoopPlaysFullSize() {
        launchDesign()
        let card = element("autopilot.design.direction.0")
        card.descendants(matching: .any).matching(identifier: "autopilot.direction.extra.0").firstMatch.click()
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 5))
        let title = element("studio.viewer.title")
        XCTAssertTrue(text(of: title).hasPrefix("Quiet Indigo · Header"), text(of: title))
        let time = element("artwork.loop.time")
        XCTAssertTrue(time.waitForExistence(timeout: 20), "The loop plays")
        let start = text(of: time)
        XCTAssertTrue(waitUntil(timeout: 5) { self.text(of: time) != start }, "The time moves while it plays: \(start)")
        attachScreenshot("Design · header loop playing")

        app.buttons["artwork.loop.play"].click()
        let paused = text(of: time)
        RunLoop.current.run(until: .now.addingTimeInterval(2.5))
        XCTAssertEqual(text(of: time), paused, "Paused, it stays put")

        element("studio.viewer.next").click()
        XCTAssertTrue(waitUntil { self.text(of: title).hasPrefix("Quiet Indigo · Search results") }, text(of: title))
    }

    func testThePosterOpensTheRecording() {
        launchDesign()
        let card = element("autopilot.design.direction.0")
        card.descendants(matching: .any).matching(identifier: "autopilot.direction.extra.2").firstMatch.click()
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("studio.viewer.title")).hasPrefix("Raw recording"), text(of: element("studio.viewer.title")))
        let subtitle = text(of: element("studio.viewer.subtitle"))
        XCTAssertTrue(subtitle.contains("The App Preview is cut from this recording"), subtitle)
        attachScreenshot("Design · recording full size")
    }

    func testChooseSaysWhatANoteCanChange() {
        app.launch(debugScene: "st-choose-extras")
        let note = element("autopilot.choose.noteScope")
        XCTAssertTrue(note.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: note).hasPrefix("A note changes the screenshots and the header and search images"), text(of: note))
        let extra = app.descendants(matching: .any).matching(identifier: "autopilot.direction.extra.0").firstMatch
        XCTAssertTrue(extra.exists)
        extra.click()
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 5), "Choose's header opens full size too")
    }

    // MARK: - Helpers

    private func launchDesign() {
        app.launch(debugScene: "st-des-revise-motion")
        XCTAssertTrue(element("autopilot.design").waitForExistence(timeout: 20))
        XCTAssertTrue(element("autopilot.design.direction.2").waitForExistence(timeout: 5))
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
