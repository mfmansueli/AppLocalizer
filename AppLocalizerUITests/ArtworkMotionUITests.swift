//
//  ArtworkMotionUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Header and search, still or motion (board 32), on
/// `StudioDebugArtMotion`'s scenes, in the guided sheet: What to make's
/// Still or Moving, Look's "The search image shows" and artwork size, a
/// run back from Cancel Run still editable, the expected result (the
/// designer's note on Look), and a loop full size with Show iPhone Area.
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

    /// What to make says whether the header and search move; Look picks
    /// what the search image shows.
    func testStillOrMotionAndWhatTheArtworkShows() {
        app.launch(debugScene: "st-plan-motion")
        let loop = element("autopilot.guided.make.motion.loop")
        XCTAssertTrue(loop.waitForExistence(timeout: 20))
        XCTAssertTrue(loop.isSelected)
        let footer = element("autopilot.guided.footer.text")
        XCTAssertTrue(text(of: footer).contains("moving header and search artwork"), text(of: footer))
        attachScreenshot("What to make · moving")

        let still = element("autopilot.guided.make.motion.still")
        tap("autopilot.guided.make.motion.still")
        XCTAssertTrue(waitUntil { still.isSelected })
        XCTAssertTrue(waitUntil { !self.text(of: footer).contains("moving") }, text(of: footer))

        element("autopilot.guided.next").click()
        let phone = element("autopilot.guided.look.shows.phone")
        XCTAssertTrue(phone.waitForExistence(timeout: 5))
        XCTAssertTrue(phone.isSelected, "A phone with the app unless the person picks another")
        let scene = element("autopilot.guided.look.shows.scene")
        tap("autopilot.guided.look.shows.scene")
        XCTAssertTrue(waitUntil { scene.isSelected })
        XCTAssertFalse(phone.isSelected)
        attachScreenshot("Look · still scene")
    }

    /// Look can make only the header or only search results. The header
    /// alone has no search image, so "The search image shows" goes;
    /// either one alone can still move.
    func testOnlyTheHeaderOrOnlySearchResults() {
        app.launch(debugScene: "st-plan-motion")
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        next.click()
        let size = element("autopilot.guided.look.artworkSize")
        XCTAssertTrue(size.waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.guided.look.shows").exists)
        reveal(size)
        size.click()
        let headerOnly = app.menuItems["Header 21:9 only"]
        XCTAssertTrue(headerOnly.waitForExistence(timeout: 5))
        XCTAssertTrue(app.menuItems["Search results 3:2 only"].exists)
        headerOnly.click()
        XCTAssertTrue(waitUntil { !self.element("autopilot.guided.look.shows").exists }, "No search image to show anything")
        attachScreenshot("Look · header only")
        expectWhatToMake("moving header artwork", "The header alone still moves")

        reveal(size)
        size.click()
        app.menuItems["Search results 3:2 only"].click()
        XCTAssertTrue(element("autopilot.guided.look.shows").waitForExistence(timeout: 5))
        attachScreenshot("Look · search results only")
        expectWhatToMake("moving search results artwork", "Search results alone still move")
    }

    /// A run back at the plan after Cancel Run (it started once) can still
    /// change still or motion, what the search image shows and the
    /// expected result, like a new one.
    func testAPlanBackFromCancelRunCanStillBeChanged() {
        app.launch(debugScene: "st-plan-motion-again")
        let still = element("autopilot.guided.make.motion.still")
        XCTAssertTrue(still.waitForExistence(timeout: 20))
        XCTAssertTrue(element("autopilot.guided.make.motion.loop").isSelected)
        XCTAssertTrue(still.isEnabled, "Still or motion can change")
        tap("autopilot.guided.make.motion.still")
        XCTAssertTrue(waitUntil { still.isSelected })

        element("autopilot.guided.next").click()
        let scene = element("autopilot.guided.look.shows.scene")
        XCTAssertTrue(scene.waitForExistence(timeout: 5))
        XCTAssertTrue(scene.isEnabled, "What it shows can change")
        tap("autopilot.guided.look.shows.scene")
        XCTAssertTrue(waitUntil { scene.isSelected })

        let note = element("autopilot.guided.look.note")
        reveal(note)
        XCTAssertTrue(note.isEnabled, "The expected result can be written")
        attachScreenshot("Look after Cancel Run · still editable")
    }

    /// The expected result is the note to the designer on Look, with its
    /// two references.
    func testTheExpectedResultIsTheDesignersNote() {
        app.launch(debugScene: "st-plan-art-custom")
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        next.click()
        let note = element("autopilot.guided.look.note")
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil { self.text(of: note).hasPrefix("A calm night sky over hills") }, text(of: note))
        let card = element("autopilot.guided.look.noteCard")
        for name in ["video-search-results-dark.mp4", "video-product-page-header-dark.mp4"] {
            let shown = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", name, name)
            XCTAssertTrue(card.descendants(matching: .any).matching(shown).firstMatch.exists, name)
        }
        attachScreenshot("Look · expected result")
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

    /// Back on What to make, its sentence says it makes `what`; then on to
    /// Look again.
    private func expectWhatToMake(_ what: String, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        element("autopilot.guided.back").click()
        let footer = element("autopilot.guided.footer.text")
        XCTAssertTrue(waitUntil { self.text(of: footer).contains(what) }, "\(message): \(text(of: footer))", file: file, line: line)
        element("autopilot.guided.next").click()
        XCTAssertTrue(element("autopilot.guided.look.artworkSize").waitForExistence(timeout: 5), "Back at Look", file: file, line: line)
    }

    /// Scrolls the guided sheet's step until `target` is inside what it
    /// shows.
    private func reveal(_ target: XCUIElement) {
        let step = element("autopilot.guided.sheet").scrollViews.firstMatch
        guard step.waitForExistence(timeout: 5), target.waitForExistence(timeout: 5) else { return }
        var tries = 0
        while !(target.frame.minY >= step.frame.minY && target.frame.maxY <= step.frame.maxY), tries < 12 {
            step.scroll(byDeltaX: 0, deltaY: target.frame.minY < step.frame.minY ? 200 : -200)
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
