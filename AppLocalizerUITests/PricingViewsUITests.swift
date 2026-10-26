//
//  PricingViewsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Subscription Pricing beyond the table: the tile map and histogram, the
/// schedule sheet, Results and Offers, driven through the DEBUG scenes in
/// `PricingDebugScenes` (sample data; nothing leaves the Mac).
@MainActor
final class PricingViewsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testSwitchingToTheMapAndTheHistogram() {
        launch(scene: "pricing-applied")
        let picker = element("pricing.displayPicker")
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        segment(1, of: picker).click()
        XCTAssertTrue(element("pricing.tileMap").waitForExistence(timeout: 5))
        XCTAssertFalse(element("pricing.matrix").exists)
        element("pricing.tile.BRA").hover()
        XCTAssertTrue(element("pricing.tileDetail").waitForExistence(timeout: 5))

        segment(2, of: picker).click()
        XCTAssertTrue(element("pricing.histogram").waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("pricing.histogram.summary")).hasPrefix("Median "))

        segment(0, of: picker).click()
        XCTAssertTrue(element("pricing.matrix").waitForExistence(timeout: 5))
    }

    func testTheScheduleWarnsAboutIncreases() {
        launch(scene: "schedule")
        XCTAssertTrue(element("pricing.scheduleSheet").waitForExistence(timeout: 10))
        let consent = element("pricing.schedule.consent")
        XCTAssertTrue(consent.exists)
        let title = consent.staticTexts.matching(NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", "go up", "go up")).firstMatch
        XCTAssertTrue(title.exists)
        XCTAssertTrue(text(of: title).contains("existing subscribers"))
        app.buttons["pricing.schedule.cancel"].click()
        XCTAssertTrue(element("pricing.scheduleSheet").waitForNonExistence(timeout: 5))
    }

    func testSchedulingTheChangesForADate() {
        launch(scene: "pricing-applied")
        let schedule = app.buttons["pricing.schedule"]
        XCTAssertTrue(schedule.waitForExistence(timeout: 10))
        let before = schedule.label
        schedule.click()
        XCTAssertTrue(element("pricing.scheduleSheet").waitForExistence(timeout: 5))
        element("pricing.schedule.start").radioButtons["On a date"].click()
        app.checkBoxes["pricing.schedule.keep"].click()
        app.buttons["pricing.schedule.save"].click()
        XCTAssertTrue(element("pricing.scheduleSheet").waitForNonExistence(timeout: 5))
        XCTAssertNotEqual(schedule.label, before)
        XCTAssertTrue(schedule.label.hasPrefix("Starts "))
    }

    func testRestoringATerritoryFromResults() {
        launch(scene: "results")
        XCTAssertTrue(element("pricing.results.table").waitForExistence(timeout: 10))
        let restore = app.buttons["pricing.results.restore.JPN"]
        XCTAssertTrue(restore.waitForExistence(timeout: 10))
        let before = reviewCount()
        restore.click()
        XCTAssertTrue(element("pricing.results.restored.JPN").waitForExistence(timeout: 5))
        XCTAssertFalse(restore.exists)
        XCTAssertEqual(reviewCount(), before + 1)
        app.buttons["workspace.reviewPushButton"].click()
        XCTAssertTrue(element("review.row.price.6450100002.JPN").waitForExistence(timeout: 5))
    }

    func testTheOffersTable() {
        launch(scene: "offers")
        let table = element("pricing.offers.table")
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        XCTAssertEqual(elements(prefixed: "pricing.offers.row.").count, 9)
        XCTAssertTrue(element("pricing.offers.row.USA").exists)
        element("pricing.offer.intro").click()
        let title = element("pricing.offerDetail").staticTexts.matching(NSPredicate(format: "value == %@ OR label == %@", "1 week free", "1 week free"))
        XCTAssertTrue(title.firstMatch.waitForExistence(timeout: 5))
    }

    func testTheViewPickerOpensOffersAndResults() {
        launch(scene: "pricing-applied")
        let picker = element("pricing.viewPicker")
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        segment(1, of: picker).click()
        XCTAssertTrue(element("pricing.offers").waitForExistence(timeout: 5))
        segment(2, of: picker).click()
        XCTAssertTrue(element("pricing.results").waitForExistence(timeout: 5))
        segment(0, of: picker).click()
        XCTAssertTrue(element("pricing.matrix").waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func elements(prefixed prefix: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
    }

    /// One segment of an `NSSegmentedControl`, which macOS exposes as a
    /// radio group.
    private func segment(_ index: Int, of control: XCUIElement) -> XCUIElement {
        control.radioButtons.element(boundBy: index)
    }

    /// A text element's string: its value on macOS, else its label.
    private func text(of element: XCUIElement) -> String {
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }

    /// The number on Review & Push, from "N pending changes".
    private func reviewCount() -> Int {
        let value = app.buttons["workspace.reviewPushButton"].value as? String ?? ""
        return Int(value.prefix { $0.isNumber }) ?? 0
    }
}
