//
//  ConnectUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The connect screen, driven through the DEBUG scenes
/// (`-AppLocalizerDebugScene <id>`): canned services, an in-memory key
/// store, no App Store Connect and no Keychain.
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
        type("ABCDE12345", into: "connect.keyIDField")
        // Still no private key.
        XCTAssertFalse(connect.isEnabled)
        XCTAssertTrue(app.buttons["connect.chooseKeyButton"].exists)
    }

    func testMalformedIssuerIDShowsAHint() {
        launch(scene: "connect")
        type("not-a-uuid", into: "connect.issuerIDField")
        XCTAssertTrue(element("connect.issuerIDIssue").waitForExistence(timeout: 5))
    }

    func testImportedKeyFillsTheKeyIDAndConnects() {
        launch(scene: "connect-key")
        XCTAssertTrue(element("connect.importedKeyName").waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["connect.keyIDField"].value as? String, "2X9R4HXF34")

        type("69a6de7f-3c2e-47e3-e053-5b8c7c11a4d1", into: "connect.issuerIDField")
        let connect = app.buttons["connect.connectButton"]
        XCTAssertTrue(connect.isEnabled)
        connect.click()

        // The debug services accept the key and the app library opens.
        XCTAssertTrue(element("sidebar.app.6450000001").waitForExistence(timeout: 10))
    }

    func testRemovingTheKeyBringsBackTheDropZone() {
        launch(scene: "connect-key")
        let remove = app.buttons["connect.removeKeyButton"]
        XCTAssertTrue(remove.waitForExistence(timeout: 10))
        remove.click()
        XCTAssertTrue(app.buttons["connect.chooseKeyButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["connect.connectButton"].isEnabled)
    }

    func testRejectedKeyShowsTheErrorAndStaysOnTheForm() {
        launch(scene: "connect-rejected")
        let connect = app.buttons["connect.connectButton"]
        XCTAssertTrue(connect.waitForExistence(timeout: 10))
        connect.click()
        XCTAssertTrue(element("connect.error").waitForExistence(timeout: 10))
        XCTAssertTrue(connect.exists)
        XCTAssertFalse(element("sidebar.appList").exists)
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
