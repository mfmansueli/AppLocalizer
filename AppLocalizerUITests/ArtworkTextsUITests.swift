//
//  ArtworkTextsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The header and search artwork's own texts and checks: Captions' Search
/// results and Header columns (`cap-artwork`), its phrase columns
/// (`cap-artwork-phrases`), and the Screenshots preview's Header and search
/// card with a check that stops the push (`st-ready-extras-details`).
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

    /// A phrase the page writes itself is a column too: English as the
    /// page wrote it, German translated, French missing; written in the
    /// editor, French's cell shows it.
    func testEachPhraseHasAColumnToTranslateIn() {
        app.launch(debugScene: "cap-artwork-phrases")
        let english = element("screenshots.captions.artwork.en-US.text.0")
        XCTAssertTrue(english.waitForExistence(timeout: 30))
        XCTAssertTrue(english.label.contains("English (U.S.) phrase 1: Small steps count."), english.label)
        let german = element("screenshots.captions.artwork.de-DE.text.0")
        XCTAssertTrue(german.label.contains("Kleine Schritte zählen."), german.label)
        let french = element("screenshots.captions.artwork.fr-FR.text.0")
        XCTAssertTrue(french.label.contains("Missing"), french.label)

        // The scene opens French's phrase in the editor.
        let title = element("screenshots.captions.artworkEditor.title")
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: title), "Phrase 1 · French")
        let original = NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", "Small steps count.", "Small steps count.")
        let sources = element("screenshots.captions.artworkEditor.sources")
        XCTAssertTrue(sources.descendants(matching: .staticText).matching(original).firstMatch.exists, "The original words to start from")
        XCTAssertFalse(element("screenshots.captions.artworkEditor.count").exists, "A phrase has no word limit of its own")

        let field = element("screenshots.captions.artworkEditor.headline")
        field.click()
        field.typeText("Les petits pas comptent.")
        let written = NSPredicate(format: "label CONTAINS %@", "Les petits pas comptent.")
        expectation(for: written, evaluatedWith: french)
        waitForExpectations(timeout: 10)
        let shot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        shot.name = "Captions phrase column"
        shot.lifetime = .keepAlways
        add(shot)
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
