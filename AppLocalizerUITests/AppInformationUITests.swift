//
//  AppInformationUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// App Information, driven through the DEBUG scenes in
/// `AppInformationDebugScenes` (sample data, simulated App Store Connect;
/// nothing leaves the Mac).
@MainActor
final class AppInformationUITests: XCTestCase {
    private var app: XCUIApplication!
    private let lumen = "6450000001"

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testThePageColumnSwitchesPages() {
        launch(scene: "info-general")
        XCTAssertTrue(element("appInformation.general").waitForExistence(timeout: 10))
        element("appInformation.pageRow.ageRating").click()
        XCTAssertTrue(element("appInformation.ageRating").waitForExistence(timeout: 5))
        element("appInformation.pageRow.exportCompliance").click()
        XCTAssertTrue(element("appInformation.exportCompliance").waitForExistence(timeout: 5))
        element("appInformation.pageRow.appPrivacy").click()
        XCTAssertTrue(element("appInformation.appPrivacy.notASync").waitForExistence(timeout: 5))
    }

    func testEditingCopyrightQueuesAChange() {
        launch(scene: "info-general")
        let copyright = app.textFields["appInformation.general.copyright"]
        XCTAssertTrue(copyright.waitForExistence(timeout: 10))
        copyright.click()
        copyright.typeKey("a", modifierFlags: .command)
        copyright.typeText("© 2027 Northpier Studio")
        app.buttons["workspace.reviewPushButton"].click()
        XCTAssertTrue(element("review.row.appInformation.\(lumen).general.lumen-v14.copyright").waitForExistence(timeout: 5))
    }

    func testDeclaringForAppleWatchInTheEditor() {
        launch(scene: "a11y-published")
        let declare = app.buttons["appInformation.accessibility.APPLE_WATCH.declare"]
        XCTAssertTrue(declare.waitForExistence(timeout: 10))
        declare.click()
        XCTAssertTrue(element("appInformation.accessibility.editor").waitForExistence(timeout: 5))
        element("appInformation.accessibility.editor.supportsAny").radioButtons["Yes"].click()
        XCTAssertFalse(element("appInformation.accessibility.editor.voiceControl").exists)
        XCTAssertTrue(element("appInformation.accessibility.editor.hidden").exists)
        app.checkBoxes["appInformation.accessibility.editor.voiceOver"].click()
        app.buttons["appInformation.accessibility.editor.save"].click()
        XCTAssertTrue(element("appInformation.accessibility.editor").waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("appInformation.toast").waitForExistence(timeout: 5))
        XCTAssertTrue(element("appInformation.accessibility.APPLE_WATCH.notPushed").exists)
    }

    func testCopyFromIPhoneSaysWhatWasLeftOut() {
        launch(scene: "a11y-published")
        let copy = app.buttons["appInformation.accessibility.APPLE_WATCH.copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 10))
        copy.click()
        let toast = element("appInformation.toast")
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertTrue(text(containing: "Voice Control isn’t available there").exists)
    }

    func testThePublishSwitchInReview() {
        launch(scene: "a11y-review")
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 10))
        let iPhone = app.switches["review.option.appInformation.\(lumen).accessibility.IPHONE"]
        let vision = app.switches["review.option.appInformation.\(lumen).accessibility.VISION"]
        XCTAssertTrue(iPhone.exists)
        XCTAssertFalse(vision.isEnabled)
        XCTAssertTrue(text(containing: "2 declarations publish immediately when pushed").exists)
        iPhone.click()
        XCTAssertTrue(text(containing: "1 declaration publishes immediately when pushed").waitForExistence(timeout: 5))
    }

    func testAnAccessibilityErrorOffersTryAgain() {
        launch(scene: "a11y-error")
        XCTAssertTrue(element("appInformation.accessibility.error").waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["appInformation.accessibility.retry"].exists)
    }

    func testAnAssistantsAnswerShowsItsEvidence() {
        launch(scene: "info-age")
        let evidence = element("appInformation.age.wellness.evidence")
        XCTAssertTrue(evidence.waitForExistence(timeout: 10))
        evidence.click()
        XCTAssertTrue(app.buttons["appInformation.evidence.confirm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["appInformation.evidence.reject"].exists)
    }

    /// Ignores saved window state, which can leave the app without a
    /// window under XCUITest.
    private func launch(scene: String) {
        app.launchArguments = ["-AppLocalizerDebugScene", scene, "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// A SwiftUI `Text` exposes its string as its value on macOS, not its
    /// label.
    private func text(containing string: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", string, string))
            .firstMatch
    }
}
