//
//  ArtworkTextsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The header and search artwork's own texts and checks: Captions' Search
/// results and Header columns (`cap-artwork`), and the checks' pills and
/// lines in Autopilot's Localize and Ready (`st-loc-extras-checks`,
/// `st-ready-extras-checks`).
@MainActor
final class ArtworkTextsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    /// Each language has a search headline cell with its fit, and an
    /// optional header line that's empty by default.
    func testCaptionsHaveSearchAndHeaderColumns() {
        app.launch(debugScene: "cap-artwork")
        let english = element("screenshots.captions.artwork.en-US.search")
        XCTAssertTrue(english.waitForExistence(timeout: 30))
        XCTAssertTrue(english.label.contains("Your calm daily journal"), english.label)
        XCTAssertTrue(english.label.contains("4 words"), english.label)
        XCTAssertTrue(element("screenshots.captions.artwork.en-US.header").label.contains("Write every day"))
        XCTAssertTrue(element("screenshots.captions.artwork.fr-FR.header").label.contains("No line"))

        let german = element("screenshots.captions.artwork.de-DE.search")
        XCTAssertTrue(german.exists)
        XCTAssertTrue(german.label.contains("Too long") || german.label.contains("Shrinks"), german.label)

        english.click()
        let editor = element("screenshots.captions.artworkEditor")
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue(element("screenshots.captions.artworkEditor.count").exists)
    }

    /// Localize shows each finding like a screenshot's check: pills, then
    /// the lines, and the error makes the row a problem.
    func testLocalizeShowsTheChecks() {
        app.launch(debugScene: "st-loc-extras-checks")
        // The row reads as one element, its checks included.
        let row = element("autopilot.localize.artwork")
        XCTAssertTrue(row.waitForExistence(timeout: 30))
        let said = text(of: row)
        XCTAssertTrue(said.contains("Rendered in"), said)
        XCTAssertTrue(said.contains("Discount"), said)
        XCTAssertTrue(said.contains("Contrast"), said)
        XCTAssertTrue(said.contains("German header: ‘−50%’ — discounts and percentages aren’t allowed here."), said)
        XCTAssertTrue(said.contains("Japanese search image: its edges melt into the page in Dark Mode."), said)
    }

    func testReadyShowsTheChecksUnderTheArtworkNote() {
        app.launch(debugScene: "st-ready-extras-checks")
        let checks = element("autopilot.ready.artwork.checks")
        XCTAssertTrue(checks.waitForExistence(timeout: 30))
        let said = text(of: checks)
        XCTAssertTrue(said.contains("Discount"), said)
        XCTAssertTrue(said.contains("German header: ‘−50%’"), said)
        XCTAssertTrue(said.contains("1 more finding"), said)
    }

    // MARK: - Helpers

    /// The Screenshots preview's Header and search card, in German: the
    /// header can't go (the discount), the search image is on App Store
    /// Connect, and View Larger opens it full size.
    func testThePreviewDetailsTheHeaderAndSearchImage() {
        app.launch(debugScene: "st-ready-extras-details")
        let card = element("studio.artwork.details")
        XCTAssertTrue(card.waitForExistence(timeout: 30))
        let root = element("studio.root")
        for _ in 0..<10 where !app.windows.firstMatch.frame.contains(card.frame) {
            root.scroll(byDeltaX: 0, deltaY: -400)
        }
        XCTAssertEqual(text(of: element("studio.artwork.details.language")), "German")
        XCTAssertTrue(text(of: element("studio.artwork.details.header.format")).hasPrefix("3840 × 1646 · PNG"))
        XCTAssertTrue(text(of: element("studio.artwork.details.header.checks")).hasPrefix("Can’t be pushed: German header: ‘−50%’"))
        XCTAssertEqual(text(of: element("studio.artwork.details.search.status")), "On App Store Connect")
        let languages = text(of: element("studio.artwork.details.languages"))
        XCTAssertTrue(languages.hasPrefix("12 languages · 1 on App Store Connect"), languages)
        let shot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        shot.name = "Header and search details"
        shot.lifetime = .keepAlways
        add(shot)

        app.buttons["studio.artwork.details.search.view"].click()
        XCTAssertTrue(element("studio.viewer.title").waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: element("studio.viewer.title")).contains("Search results · 3:2"))
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// The label and the value, whichever it has (a text's is its value).
    private func text(of element: XCUIElement) -> String {
        [element.label, element.value as? String ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
