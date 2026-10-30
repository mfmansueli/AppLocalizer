//
//  SettingsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The Settings window, opened by the DEBUG scenes in `SettingsDebugScenes`
/// with the design's two sample keys, in memory (no Keychain, no Apple).
@MainActor
final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testAccountListsBothKeysWithTheirChecks() {
        launch(scene: "set-account")
        XCTAssertTrue(element("settings.key.2X9R4HXF34").waitForExistence(timeout: 10))
        XCTAssertTrue(element("settings.key.Q7MZ3K8PLA").exists)
        XCTAssertTrue(app.staticTexts["Northpier Studio"].exists)
        XCTAssertTrue(app.staticTexts["In use"].exists)
        XCTAssertTrue(app.staticTexts["Can’t read Sales and Trends, so price suggestions use purchasing power only"].exists)
    }

    func testTestConnectionRefreshesTheCheck() {
        launch(scene: "set-account")
        let test = app.buttons["settings.test.Q7MZ3K8PLA"]
        XCTAssertTrue(test.waitForExistence(timeout: 10))
        test.click()
        // The debug checker finds Sales and Trends readable this time.
        XCTAssertTrue(app.staticTexts["Can’t read Sales and Trends, so price suggestions use purchasing power only"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Can manage apps and read Sales and Trends").count, 2)
    }

    func testRemovingAKeyAsksFirst() {
        launch(scene: "set-account")
        let remove = app.buttons["settings.remove.Q7MZ3K8PLA"]
        XCTAssertTrue(remove.waitForExistence(timeout: 10))
        remove.click()
        // Inside a window: the Touch Bar shows the same button.
        let confirm = app.windows.descendants(matching: .button)["Remove Key"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.click()
        XCTAssertTrue(element("settings.key.Q7MZ3K8PLA").waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("settings.key.2X9R4HXF34").exists)
    }

    func testAddAnotherKeyOpensTheConnectForm() {
        launch(scene: "set-account")
        let add = app.buttons["settings.addKey"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.click()
        XCTAssertTrue(app.textFields["connect.issuerIDField"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Add Another Key"].exists)
        app.buttons["connect.cancelButton"].click()
        XCTAssertTrue(app.textFields["connect.issuerIDField"].waitForNonExistence(timeout: 5))
    }

    func testChangingTheDefaultIndexMakesTheDefaultsCustom() {
        launch(scene: "set-pricing")
        let source = element("settings.indexSource")
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["settings.restoreRecommended"].exists)
        source.click()
        app.menuItems["Big Mac Index"].click()
        let restore = app.buttons["settings.restoreRecommended"]
        XCTAssertTrue(restore.waitForExistence(timeout: 5))
        restore.click()
        XCTAssertTrue(restore.waitForNonExistence(timeout: 5))
    }

    func testGlossaryTermsCanBeAddedAndRemoved() {
        launch(scene: "set-translation")
        XCTAssertTrue(element("settings.term.Lumen Plus").waitForExistence(timeout: 10))
        app.buttons["Remove Face ID"].click()
        XCTAssertTrue(element("settings.term.Face ID").waitForNonExistence(timeout: 5))

        app.buttons["settings.addTerm"].click()
        let field = app.textFields["settings.glossaryField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Northpier\r")
        XCTAssertTrue(element("settings.term.Northpier").waitForExistence(timeout: 5))
    }

    func testProviderChoiceIsARadioGroup() {
        launch(scene: "set-translation")
        let assistant = app.buttons["settings.provider.assistant"]
        XCTAssertTrue(assistant.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["settings.provider.appleTranslation"].isSelected)
        assistant.click()
        XCTAssertTrue(assistant.isSelected)
        XCTAssertFalse(app.buttons["settings.provider.appleTranslation"].isSelected)
    }

    func testASavedAPIKeySaysItIsConnected() {
        launch(scene: "set-translation")
        XCTAssertTrue(apiKeyStatus("Saved · connected to Anthropic · 182 ms").waitForExistence(timeout: 10))
        XCTAssertFalse(element("settings.apiKeyCheckAgain").exists)
    }

    func testARejectedAPIKeyCanBeReplaced() {
        launch(scene: "set-translation-rejected")
        XCTAssertTrue(apiKeyStatus("Saved, but Anthropic rejected this key").waitForExistence(timeout: 10))
        XCTAssertTrue(element("settings.apiKeyCheckAgain").exists)

        let field = app.secureTextFields["settings.apiKey"]
        field.click()
        field.typeText("sk-ant-new\r")
        XCTAssertTrue(apiKeyStatus("Saved · connected to Anthropic · 182 ms").waitForExistence(timeout: 10))
        XCTAssertFalse(element("settings.apiKeyCheckAgain").exists)
    }

    func testGeneralConfirmations() {
        launch(scene: "set-general")
        let picker = element("settings.pushConfirmation")
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        XCTAssertEqual(picker.radioButtons["Over 50 changes"].value as? Int, 1)
        picker.radioButtons["Always"].click()
        XCTAssertEqual(picker.radioButtons["Always"].value as? Int, 1)
        XCTAssertEqual(picker.radioButtons["Over 50 changes"].value as? Int, 0)
        XCTAssertTrue(element("settings.commission").exists)
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// The line under the API key field, once it says `text`.
    private func apiKeyStatus(_ text: String) -> XCUIElement {
        app.staticTexts.matching(identifier: "settings.apiKeyStatus")
            .matching(NSPredicate(format: "value == %@ OR label == %@", text, text))
            .firstMatch
    }
}
