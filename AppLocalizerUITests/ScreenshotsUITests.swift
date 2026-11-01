//
//  ScreenshotsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Screenshots, driven through the DEBUG scenes in
/// `ScreenshotsDebugScenes` (sample documents and live sets, nothing
/// leaves the Mac): the Sets matrix, the full-size viewer and the Locale
/// Scope sheet.
@MainActor
final class ScreenshotsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testSetsShowsTheMatrixAndTheFailedChecksBanner() {
        launch(scene: "sets")
        XCTAssertTrue(element("screenshots.sets").waitForExistence(timeout: 15))
        XCTAssertTrue(element("screenshots.banner.failedChecks").exists)
        // The title and the message read as one paragraph.
        let summary = NSPredicate(format: "value BEGINSWITH %@ OR label BEGINSWITH %@", "2 renders fail their checks.", "2 renders fail their checks.")
        XCTAssertTrue(app.staticTexts.matching(summary).firstMatch.exists)
        XCTAssertTrue(element("screenshots.row.en-US").exists)
        XCTAssertTrue(element("screenshots.row.ar-SA").exists)
        XCTAssertTrue(app.buttons["screenshots.scopeButton"].exists)
        XCTAssertTrue(element("screenshots.overflowCount").exists)
    }

    func testTheFallbackLocalesExpandAndCollapse() {
        launch(scene: "sets")
        // The fallback group is last, and the matrix only builds the rows
        // it shows: scroll to the end first.
        let sets = element("screenshots.sets")
        XCTAssertTrue(sets.waitForExistence(timeout: 15))
        let toggle = element("screenshots.sets.toggleFallback")
        XCTAssertTrue(scrollToEnd(sets, until: toggle))
        XCTAssertFalse(element("screenshots.row.da").exists)
        toggle.click()
        XCTAssertTrue(scrollDown(sets, until: element("screenshots.row.da")))
    }

    func testTheBannerOpensTheFirstFailureInTheViewer() {
        launch(scene: "sets")
        let show = app.buttons["screenshots.banner.show"]
        XCTAssertTrue(show.waitForExistence(timeout: 15))
        show.click()
        XCTAssertTrue(element("screenshots.viewer").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Slot 3 · Search"].exists)
        XCTAssertTrue(app.staticTexts["6 of 12"].exists)
        XCTAssertTrue(app.staticTexts["1 line too many at 80 u"].exists)
    }

    func testTheViewerStepsThroughTheLocalizedSets() {
        launch(scene: "viewer")
        XCTAssertTrue(element("screenshots.viewer").waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["2 of 12"].exists)
        app.buttons["screenshots.viewer.next"].click()
        XCTAssertTrue(app.staticTexts["3 of 12"].waitForExistence(timeout: 5))
        app.buttons["screenshots.viewer.locale.de-DE"].click()
        XCTAssertTrue(app.staticTexts["6 of 12"].waitForExistence(timeout: 5))
        app.buttons["screenshots.viewer.done"].click()
        XCTAssertTrue(element("screenshots.viewer").waitForNonExistence(timeout: 5))
    }

    func testClickingACellOpensTheViewer() {
        launch(scene: "sets")
        let cell = element("screenshots.cell.fr-FR.0")
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        cell.click()
        XCTAssertTrue(element("screenshots.viewer").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Slot 1 · Today"].exists)
    }

    func testTheScopeSheetEstimatesAndSaves() {
        launch(scene: "sets")
        let scope = app.buttons["screenshots.scopeButton"]
        XCTAssertTrue(scope.waitForExistence(timeout: 15))
        scope.click()
        XCTAssertTrue(element("screenshots.scope").waitForExistence(timeout: 5))
        let estimate = element("screenshots.scope.estimate")
        XCTAssertTrue(text(of: estimate).hasPrefix("12 locales × 5 slots × 2 display types"), text(of: estimate))

        app.checkBoxes["screenshots.scope.toggle.da"].click()
        XCTAssertTrue(text(of: estimate).hasPrefix("13 locales"), text(of: estimate))
        app.buttons["screenshots.scope.save"].click()
        XCTAssertTrue(element("screenshots.scope").waitForNonExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(app.buttons["screenshots.scopeButton"], "13 of 39 locales localized"))
    }

    func testCancellingTheScopeChangesNothing() {
        launch(scene: "scope")
        XCTAssertTrue(element("screenshots.scope").waitForExistence(timeout: 15))
        app.buttons["screenshots.scope.all"].click()
        let estimate = element("screenshots.scope.estimate")
        XCTAssertTrue(text(of: estimate).hasPrefix("39 locales"), text(of: estimate))
        app.buttons["screenshots.scope.cancel"].click()
        XCTAssertTrue(element("screenshots.scope").waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.buttons["screenshots.scopeButton"].label, "12 of 39 locales localized")
    }

    func testNoCapturesExplainsWhatACaptureIs() {
        launch(scene: "sets-empty")
        XCTAssertTrue(element("screenshots.noCaptures").waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["screenshots.importCaptures"].exists)
        XCTAssertTrue(app.buttons["screenshots.useLive"].exists)
    }

    func testPickingAStarterShowsTheMatrix() {
        launch(scene: "sets-notpl")
        let starter = app.buttons["screenshots.starter.above"]
        XCTAssertTrue(starter.waitForExistence(timeout: 15))
        starter.click()
        XCTAssertTrue(element("screenshots.sets").waitForExistence(timeout: 15))
    }

    /// iPhone Duo is listed under Coming soon; picking it shows its row,
    /// which has nothing to push until it has captures.
    func testIPhoneDuoIsComingSoonInTheDisplayMenu() {
        launch(scene: "sets")
        let menu = element("screenshots.displayType")
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        menu.click()
        let duo = app.menuItems.matching(
            NSPredicate(format: "identifier == %@ OR title BEGINSWITH %@", "screenshots.display.iPhone Duo", "iPhone Duo")
        ).firstMatch
        XCTAssertTrue(duo.waitForExistence(timeout: 5))
        duo.click()
        let picked = NSPredicate(format: "label CONTAINS %@ OR title CONTAINS %@", "iPhone Duo", "iPhone Duo")
        let switched = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: picked, object: menu)], timeout: 10) == .completed
        XCTAssertTrue(switched, menu.debugDescription)
        let cell = element("screenshots.cell.en-US.0")
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
        XCTAssertTrue(cell.label.contains("No capture"), cell.label)
    }

    func testALiveVersionShowsTheNoVersionBanner() {
        launch(scene: "sets-noversion")
        XCTAssertTrue(element("screenshots.banner.noVersion").waitForExistence(timeout: 15))
        XCTAssertTrue(element("screenshots.sets").exists)
    }

    /// Scrolls to the end of `scrollView` until `target` exists; rows can
    /// still be growing while the renders come in, so it tries a few times.
    private func scrollToEnd(_ scrollView: XCUIElement, until target: XCUIElement) -> Bool {
        for _ in 0..<4 {
            scrollView.scroll(byDeltaX: 0, deltaY: -10000)
            if target.waitForExistence(timeout: 2) { return true }
        }
        return false
    }

    /// Scrolls `scrollView` down a little at a time until `target` exists:
    /// the rows just shown are below the ones on screen.
    private func scrollDown(_ scrollView: XCUIElement, until target: XCUIElement) -> Bool {
        for _ in 0..<20 {
            if target.waitForExistence(timeout: 1) { return true }
            scrollView.scroll(byDeltaX: 0, deltaY: -300)
        }
        return target.exists
    }

    private func waitForLabel(_ element: XCUIElement, _ label: String) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 10) == .completed
    }

    /// A static text's string is its value on macOS; a button's is its label.
    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
