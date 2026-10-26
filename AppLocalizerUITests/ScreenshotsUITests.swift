//
//  ScreenshotsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Store Page → Screenshots, driven through the DEBUG scenes in
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
        XCTAssertTrue(app.staticTexts["2 renders fail their checks."].exists)
        XCTAssertTrue(element("screenshots.row.en-US").exists)
        XCTAssertTrue(element("screenshots.row.ar-SA").exists)
        XCTAssertTrue(app.buttons["screenshots.scopeButton"].exists)
        XCTAssertTrue(element("screenshots.overflowCount").exists)
    }

    func testTheFallbackLocalesExpandAndCollapse() {
        launch(scene: "sets")
        let toggle = app.buttons["screenshots.sets.toggleFallback"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 15))
        XCTAssertFalse(element("screenshots.row.da").exists)
        toggle.click()
        XCTAssertTrue(element("screenshots.row.da").waitForExistence(timeout: 5))
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
        XCTAssertTrue(estimate.label.hasPrefix("12 locales × 5 slots × 2 display types"), estimate.label)

        app.checkBoxes["screenshots.scope.toggle.da"].click()
        XCTAssertTrue(element("screenshots.scope.estimate").label.hasPrefix("13 locales"))
        app.buttons["screenshots.scope.save"].click()
        XCTAssertTrue(element("screenshots.scope").waitForNonExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(app.buttons["screenshots.scopeButton"], "13 of 39 locales localized"))
    }

    func testCancellingTheScopeChangesNothing() {
        launch(scene: "scope")
        XCTAssertTrue(element("screenshots.scope").waitForExistence(timeout: 15))
        app.buttons["screenshots.scope.all"].click()
        XCTAssertTrue(element("screenshots.scope.estimate").label.hasPrefix("39 locales"))
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

    func testALiveVersionShowsTheNoVersionBanner() {
        launch(scene: "sets-noversion")
        XCTAssertTrue(element("screenshots.banner.noVersion").waitForExistence(timeout: 15))
        XCTAssertTrue(element("screenshots.sets").exists)
    }

    private func waitForLabel(_ element: XCUIElement, _ label: String) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 10) == .completed
    }

    private func launch(scene: String) {
        app.launchArguments = ["-AppLocalizerDebugScene", scene]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
