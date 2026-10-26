//
//  ConnectUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The connect screen and the first sync, driven through the DEBUG scenes
/// in `ConnectDebugScenes` (`-AppLocalizerDebugScene <id>`): canned key
/// checks, an in-memory key store, no App Store Connect and no Keychain.
@MainActor
final class ConnectUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testConnectStaysDisabledUntilTheFormIsComplete() {
        launch(scene: "connect")
        let connect = app.buttons["connect.connectButton"]
        XCTAssertTrue(connect.waitForExistence(timeout: 10))
        XCTAssertFalse(connect.isEnabled)

        type("69a6de7f-3c2e-47e3-e053-5b8c7c11a4d1", into: "connect.issuerIDField")
        type("abcde12345", into: "connect.keyIDField")
        XCTAssertEqual(app.textFields["connect.keyIDField"].value as? String, "ABCDE12345")
        // Still no private key.
        XCTAssertFalse(connect.isEnabled)
        XCTAssertTrue(element("connect.chooseKeyButton").exists)
    }

    func testMalformedIssuerIDShowsAHintAfterLeavingTheField() {
        launch(scene: "connect")
        type("not-a-uuid", into: "connect.issuerIDField")
        XCTAssertFalse(element("connect.issuerIDField.issue").exists)
        app.textFields["connect.keyIDField"].click()
        XCTAssertTrue(element("connect.issuerIDField.issue").waitForExistence(timeout: 5))
    }

    func testWrongFileAndMalformedIDsExplainThemselves() {
        launch(scene: "connect-hints")
        XCTAssertTrue(element("connect.rejectedFile").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["A Key ID is 10 capital letters and digits, like 2X9R4HXF34."].exists)
        XCTAssertTrue(element("connect.issuerIDField.issue").exists)
        XCTAssertTrue(app.buttons["connect.chooseAgainButton"].exists)
        XCTAssertFalse(app.buttons["connect.connectButton"].isEnabled)
    }

    func testImportedKeyConnectsAndTheFirstSyncOpensTheLibrary() {
        launch(scene: "connect-key")
        XCTAssertTrue(element("connect.importedKeyName").waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["connect.keyIDField"].value as? String, "2X9R4HXF34")

        type("69a6de7f-3c2e-47e3-e053-5b8c7c11a4d1", into: "connect.issuerIDField")
        let connect = app.buttons["connect.connectButton"]
        XCTAssertTrue(connect.isEnabled)
        connect.click()

        // The debug checker accepts the key, the first sync runs, then the
        // library opens.
        XCTAssertTrue(element("sidebar.app.6450000001").waitForExistence(timeout: 30))
    }

    func testRemovingTheKeyBringsBackTheDropZone() {
        launch(scene: "connect-key")
        let remove = app.buttons["connect.removeKeyButton"]
        XCTAssertTrue(remove.waitForExistence(timeout: 10))
        remove.click()
        XCTAssertTrue(element("connect.chooseKeyButton").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["connect.connectButton"].isEnabled)
    }

    func testRejectedKeyShowsTheErrorAndStaysOnTheForm() {
        launch(scene: "connect-rejected")
        let connect = app.buttons["connect.connectButton"]
        XCTAssertTrue(connect.waitForExistence(timeout: 10))
        connect.click()
        XCTAssertTrue(app.staticTexts["App Store Connect rejected this key (401)."].waitForExistence(timeout: 10))
        XCTAssertTrue(connect.exists)
        XCTAssertFalse(element("sidebar.appList").exists)
    }

    func testRoleTooLowNamesTheRolesThatWork() {
        launch(scene: "connect-403")
        XCTAssertTrue(app.staticTexts["This key’s role can’t manage apps (403)."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Create a Team Key with the Admin or App Manager role, then connect again."].exists)
    }

    func testOfflineOffersTryAgain() {
        launch(scene: "connect-offline")
        let retry = app.buttons["connect.retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        retry.click()
        // Still offline: the banner comes back after the retry.
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
    }

    func testHelpExplainsWhereTheKeyComesFrom() {
        launch(scene: "connect")
        let help = app.buttons["connect.helpDisclosure"]
        XCTAssertTrue(help.waitForExistence(timeout: 10))
        XCTAssertFalse(element("connect.openAppStoreConnectLink").exists)
        help.click()
        XCTAssertTrue(element("connect.openAppStoreConnectLink").waitForExistence(timeout: 5))
    }

    func testAddAnotherKeyFromTheAccountSwitcher() {
        launch(scene: "apps")
        let switcher = element("sidebar.accountSwitcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        switcher.click()
        // The switcher's menu, not the same item in the AppLocalizer menu.
        switcher.menuItems["Add Another Key…"].click()
        XCTAssertTrue(app.staticTexts["Add Another Key"].waitForExistence(timeout: 5))
        app.buttons["connect.cancelButton"].click()
        XCTAssertTrue(app.staticTexts["Add Another Key"].waitForNonExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launchArguments = ["-AppLocalizerDebugScene", scene]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func type(_ text: String, into identifier: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.click()
        field.typeText(text)
    }
}
