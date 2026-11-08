//
//  AutopilotDesignResultsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Making it with the looks designed (`st-des-revise-motion`: the three
/// looks while Claude Code makes the person's note): the looks fit the
/// sheet and a screenshot opens full size; a run that makes only the
/// header and search shows no screenshot at Making it or Choose, and
/// Choose opens its images full size. Each test attaches the window's
/// screenshot.
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
        XCTAssertTrue(element("autopilot.guided.making.revision").exists)
        let sheet = element("autopilot.guided.sheet").frame.insetBy(dx: -1, dy: -1)
        for index in 0..<3 {
            let card = element("autopilot.guided.making.look.\(index)")
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            XCTAssertTrue(sheet.minX <= card.frame.minX && card.frame.maxX <= sheet.maxX, "Look \(index) at \(card.frame) spills out of \(sheet)")
            let thumbnails = card.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnails").firstMatch
            XCTAssertTrue(thumbnails.exists, "Look \(index) has its screenshots")
            let inside = card.frame.insetBy(dx: -1, dy: -1)
            XCTAssertTrue(
                inside.minX <= thumbnails.frame.minX && thumbnails.frame.maxX <= inside.maxX,
                "The screenshots at \(thumbnails.frame) spill out of look \(index) at \(card.frame)"
            )
        }
        attachScreenshot("Making it · the looks fit")
    }

    func testAScreenshotOpensFullSize() {
        launchDesign()
        let card = element("autopilot.guided.making.look.1")
        card.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnail.2").firstMatch.click()
        let viewer = element("studio.viewer")
        XCTAssertTrue(viewer.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("studio.viewer.title")).hasPrefix("Full Bleed · 3"), text(of: element("studio.viewer.title")))
        attachScreenshot("Making it · screenshot full size")
        element("studio.viewer.close").click()
        XCTAssertTrue(waitUntil { !viewer.exists })
        XCTAssertTrue(element("autopilot.guided.making.looks").exists, "Making it stays open")
    }

    /// Choose in a run that makes screenshots and the header and search: a
    /// note is about both, and each look shows its screenshots.
    func testChooseSaysWhatANoteCanChange() {
        app.launch(debugScene: "st-choose-extras")
        let note = element("autopilot.guided.choose.scope")
        XCTAssertTrue(note.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: note).hasPrefix("A note changes the screenshots and the header and search images"), text(of: note))
        let thumbnails = app.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnails")
        XCTAssertTrue(thumbnails.firstMatch.exists, "Each look shows its screenshots")
        attachScreenshot("Choose · what a note changes")
    }

    // MARK: - Only header and search

    /// A run that makes only the header and search: Making it's looks show
    /// no screenshot, and the sheet says what the run makes.
    func testDesignWithoutScreenshotsShowsOnlyTheHeaderAndSearch() {
        app.launch(debugScene: "st-des-web-art-only")
        XCTAssertTrue(element("autopilot.guided.making.looks").waitForExistence(timeout: 20))
        let subtitle = text(of: element("autopilot.guided.sheetSubtitle"))
        XCTAssertTrue(subtitle.contains("header and search"), subtitle)
        XCTAssertFalse(subtitle.contains("screenshots"), subtitle)
        let line = text(of: element("autopilot.guided.making.line"))
        XCTAssertFalse(line.contains("screenshot looks"), line)
        for index in 0..<3 {
            let card = element("autopilot.guided.making.look.\(index)")
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            let thumbnails = card.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnails").firstMatch
            XCTAssertFalse(thumbnails.exists, "Look \(index) shows no screenshots")
        }
        attachScreenshot("Making it · only header and search")
    }

    /// The same run at Choose: each look shows only its header and search,
    /// a note is about them alone, and they open full size.
    func testChooseWithoutScreenshotsShowsOnlyTheHeaderAndSearch() {
        app.launch(debugScene: "st-choose-web-art-only")
        let note = element("autopilot.guided.choose.scope")
        XCTAssertTrue(note.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: note).hasPrefix("A note changes the header and search images"), text(of: note))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnails").firstMatch.exists, "No screenshots")
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "autopilot.direction.extras").count, 3)
        attachScreenshot("Choose · only header and search")

        app.descendants(matching: .any).matching(identifier: "autopilot.direction.extra.1").firstMatch.click()
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("studio.viewer.title")).hasPrefix("Quiet Indigo · Search results"), text(of: element("studio.viewer.title")))
    }

    // MARK: - Helpers

    private func launchDesign() {
        app.launch(debugScene: "st-des-revise-motion")
        XCTAssertTrue(element("autopilot.guided.making.looks").waitForExistence(timeout: 20))
        XCTAssertTrue(element("autopilot.guided.making.look.2").waitForExistence(timeout: 5))
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
