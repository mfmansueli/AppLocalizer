//
//  TemplateGalleryUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The template gallery and the inspector's new rows, driven through the
/// DEBUG scenes in `ScreenshotsDebugScenes` (sample documents; nothing
/// leaves the Mac): filtering by style (Bold has Arcade), switching to Cinema as a new
/// version, and adding a rating on one slot, typing its value, going back
/// to the App Store's and removing it.
@MainActor
final class TemplateGalleryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testTheGalleryFiltersByStyle() {
        app.launch(debugScene: "gallery")
        XCTAssertTrue(element("screenshots.templateGallery").waitForExistence(timeout: 15))
        let count = element("screenshots.gallery.count")
        XCTAssertTrue(waitForText(count, "14 templates"), text(of: count))
        // The grid is lazy: only the first cards are on screen.
        XCTAssertTrue(element("screenshots.gallery.card.above").exists)

        let filter = element("screenshots.gallery.style")
        filter.radioButtons["Elegant"].click()
        XCTAssertTrue(waitForText(count, "3 templates"), text(of: count))
        XCTAssertTrue(element("screenshots.gallery.card.cinema").exists)
        XCTAssertTrue(element("screenshots.gallery.card.above").waitForNonExistence(timeout: 5))

        filter.radioButtons["All"].click()
        XCTAssertTrue(waitForText(count, "14 templates"), text(of: count))
    }

    func testBoldHasFiveTemplatesWithSocialProofAndArcade() {
        app.launch(debugScene: "gallery")
        XCTAssertTrue(element("screenshots.templateGallery").waitForExistence(timeout: 15))
        let count = element("screenshots.gallery.count")
        element("screenshots.gallery.style").radioButtons["Bold"].click()
        XCTAssertTrue(waitForText(count, "5 templates"), text(of: count))
        let arcade = element("screenshots.gallery.card.arcade")
        if !arcade.waitForExistence(timeout: 3) {
            // The grid is lazy: the last cards may be below the fold.
            element("screenshots.gallery.card.boldStack").scroll(byDeltaX: 0, deltaY: -900)
        }
        XCTAssertTrue(arcade.waitForExistence(timeout: 10))
        XCTAssertTrue(element("screenshots.gallery.card.proof").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["screenshots.starter.arcade"].exists)
        XCTAssertTrue(element("screenshots.gallery.card.above").waitForNonExistence(timeout: 5))
    }

    func testSwitchingToCinemaMakesTheNextVersion() {
        app.launch(debugScene: "tpl")
        XCTAssertTrue(element("screenshots.template.canvas").waitForExistence(timeout: 15))
        XCTAssertTrue(waitForText(element("screenshots.template.version"), "v4"))
        app.buttons["screenshots.template.starters"].click()
        XCTAssertTrue(element("screenshots.templateGallery").waitForExistence(timeout: 10))
        let cinema = app.buttons["screenshots.starter.cinema"]
        XCTAssertTrue(cinema.waitForExistence(timeout: 10))
        cinema.click()
        XCTAssertTrue(element("screenshots.templateGallery").waitForNonExistence(timeout: 10))
        XCTAssertTrue(waitForText(element("screenshots.template.version"), "v5"))
    }

    func testARatingIsAddedToTheSlotAndRemoved() {
        app.launch(debugScene: "tpl")
        XCTAssertTrue(element("screenshots.template.canvas").waitForExistence(timeout: 15))
        let section = element("screenshots.template.decorations")
        XCTAssertTrue(section.waitForExistence(timeout: 5))
        XCTAssertTrue(section.staticTexts["None on this slot."].exists)

        app.buttons["screenshots.template.addDecoration.rating"].click()
        let row = element("screenshots.template.decoration.0")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.staticTexts["Rating laurel"].exists)
        // A laurel shows the App Store rating in each country until a
        // value is typed.
        XCTAssertTrue(element("screenshots.template.storeRating.0").exists, "The App Store rating, per country")
        XCTAssertFalse(app.textFields["screenshots.template.decorationValue.0"].exists)
        XCTAssertTrue(element("screenshots.template.unsaved").waitForExistence(timeout: 5))
        element("screenshots.template.typeRating.0").click()
        let value = app.textFields["screenshots.template.decorationValue.0"]
        XCTAssertTrue(value.waitForExistence(timeout: 5), "Type It: a value of its own")
        XCTAssertFalse((value.value as? String ?? "").isEmpty, "It starts from the rating shown")
        element("screenshots.template.useStoreRating.0").click()
        XCTAssertTrue(element("screenshots.template.storeRating.0").waitForExistence(timeout: 5), "Use App Store: back to the store's")

        // A link-style button.
        element("screenshots.template.removeDecoration.0").click()
        XCTAssertTrue(row.waitForNonExistence(timeout: 5))
        XCTAssertTrue(section.staticTexts["None on this slot."].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    /// Waits for a static text's value, or an element's label, to contain
    /// `expected`.
    private func waitForText(_ element: XCUIElement, _ expected: String) -> Bool {
        let predicate = NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", expected, expected)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 10) == .completed
    }

    /// A static text's string is its value on macOS; a button's is its label.
    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
