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

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        "\(element.label) \(element.value as? String ?? "")"
    }
}
