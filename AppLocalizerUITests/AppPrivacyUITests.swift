//
//  AppPrivacyUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// App Privacy, driven through the `priv-*` DEBUG scenes in
/// `AppInformationDebugScenes+Privacy` (Lumen Journal's sample worksheet,
/// simulated App Store Connect; nothing leaves the Mac). The Copy buttons
/// are never clicked, so the pasteboard is left alone.
@MainActor
final class AppPrivacyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testTheTabsSwitchBetweenTheWorksheetTheChecklistAndTheURLs() {
        launch(scene: "priv-review")
        XCTAssertTrue(element("appInformation.appPrivacy.worksheet").waitForExistence(timeout: 10))
        let tabs = element("appInformation.appPrivacy.tabs")
        tabs.radioButtons["Fill in App Store Connect"].click()
        XCTAssertTrue(element("appInformation.appPrivacy.checklist").waitForExistence(timeout: 5))
        tabs.radioButtons["Privacy URLs"].click()
        XCTAssertTrue(element("appInformation.appPrivacy.urls").waitForExistence(timeout: 5))
        tabs.radioButtons["Worksheet"].click()
        XCTAssertTrue(element("appInformation.appPrivacy.worksheet").waitForExistence(timeout: 5))
    }

    func testStartingFromScratchOpensTheWorksheet() {
        launch(scene: "priv-empty")
        let scratch = element("appInformation.appPrivacy.start.scratch")
        XCTAssertTrue(scratch.waitForExistence(timeout: 10))
        scratch.click()
        XCTAssertTrue(element("appInformation.appPrivacy.worksheet").waitForExistence(timeout: 5))
    }

    func testAcceptingASuggestion() {
        launch(scene: "priv-review")
        let accept = app.buttons["appInformation.appPrivacy.type.interaction.accept"]
        XCTAssertTrue(accept.waitForExistence(timeout: 10))
        accept.click()
        XCTAssertTrue(accept.waitForNonExistence(timeout: 5))
        XCTAssertTrue(status("Accepted", in: "interaction").exists)
    }

    func testRejectingASuggestionMakesItNotCollected() {
        launch(scene: "priv-review")
        let reject = app.buttons["appInformation.appPrivacy.type.performance.reject"]
        XCTAssertTrue(reject.waitForExistence(timeout: 10))
        reject.click()
        XCTAssertTrue(reject.waitForNonExistence(timeout: 5))
        XCTAssertTrue(status("Suggestion rejected", in: "performance").exists)
        XCTAssertFalse(element("appInformation.appPrivacy.type.performance.linked").exists)
    }

    func testAnsweringAnOpenQuestionAppliesWhatTheAnswerMeans() {
        launch(scene: "priv-review")
        let question = element("appInformation.appPrivacy.question.q1")
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        XCTAssertTrue(element("appInformation.appPrivacy.type.email.linked").exists)
        question.radioButtons["No"].click()
        XCTAssertTrue(label(containing: "Both are marked not collected.").waitForExistence(timeout: 5))
        XCTAssertTrue(element("appInformation.appPrivacy.type.email.linked").waitForNonExistence(timeout: 5))
    }

    func testKeepingYourAnswerInAConflict() {
        launch(scene: "priv-conflict")
        let keep = app.buttons["appInformation.appPrivacy.conflict.keepYours"]
        XCTAssertTrue(keep.waitForExistence(timeout: 10))
        keep.click()
        XCTAssertTrue(keep.waitForNonExistence(timeout: 5))
        XCTAssertTrue(status("Yours", in: "deviceId").exists)
    }

    func testUsingTheAssistantsAnswerInAConflict() {
        launch(scene: "priv-conflict")
        let useTheirs = app.buttons["appInformation.appPrivacy.conflict.useTheirs"]
        XCTAssertTrue(useTheirs.waitForExistence(timeout: 10))
        useTheirs.click()
        XCTAssertTrue(useTheirs.waitForNonExistence(timeout: 5))
        XCTAssertTrue(status("Accepted", in: "deviceId").exists)
    }

    func testMarkingAManifestTypeCollectedClearsTheMismatch() {
        launch(scene: "priv-mismatch")
        let banner = element("appInformation.appPrivacy.mismatch.otherDiagnostics")
        XCTAssertTrue(banner.waitForExistence(timeout: 10))
        app.buttons["appInformation.appPrivacy.mismatch.otherDiagnostics.collected"].click()
        XCTAssertTrue(banner.waitForNonExistence(timeout: 5))
    }

    func testEditingAPolicyURLQueuesAStorePageChange() {
        launch(scene: "priv-urls")
        let field = app.textFields["appInformation.appPrivacy.urls.ca.policy"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.click()
        field.typeKey("a", modifierFlags: .command)
        field.typeText("https://lumen.example/ca/privacitat")
        app.buttons["workspace.reviewPushButton"].click()
        let row = reviewRow(matching: "identifier BEGINSWITH 'review.row.storePage.' AND identifier ENDSWITH '.ca.privacyPolicyUrl'")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }

    func testEditingAChoicesURLQueuesAnAppInformationChange() {
        launch(scene: "priv-urls")
        let field = app.textFields["appInformation.appPrivacy.urls.ca.choices"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.click()
        field.typeText("https://lumen.example/ca/choices")
        app.buttons["workspace.reviewPushButton"].click()
        XCTAssertTrue(element("review.row.appInformation.6450000001.appPrivacy.choices.ca").waitForExistence(timeout: 5))
    }

    func testImportingAFastlaneFileMakesTheAnswersYours() {
        launch(scene: "priv-import")
        let importButton = app.buttons["appInformation.appPrivacy.importSheet.import"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 10))
        importButton.click()
        XCTAssertTrue(element("appInformation.appPrivacy.importSheet").waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("appInformation.appPrivacy.worksheet").waitForExistence(timeout: 5))
        XCTAssertTrue(status("Yours", in: "email").exists)
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

    /// A data type row's status pill, read by its accessibility label.
    private func status(_ title: String, in type: String) -> XCUIElement {
        element("appInformation.appPrivacy.type.\(type)")
            .descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR value == %@", "Status: \(title)", title))
            .firstMatch
    }

    /// A SwiftUI `Text` exposes its string as its value on macOS.
    private func label(containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)).firstMatch
    }

    private func reviewRow(matching format: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: format)).firstMatch
    }
}
