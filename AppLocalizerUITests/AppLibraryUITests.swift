//
//  AppLibraryUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The main window's app library and workspace, driven through the DEBUG
/// scenes `apps`, `apps-empty` and `apps-error` (canned apps from
/// `DebugFixtures`).
@MainActor
final class AppLibraryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testSidebarListsTheAccountsAppsAndSelectsTheFirst() {
        launch(scene: "apps")
        for id in ["6443000001", "6443000002", "6443000003", "6443000004"] {
            XCTAssertTrue(element("sidebar.app.\(id)").waitForExistence(timeout: 10), "missing app \(id)")
        }
        XCTAssertTrue(element("workspace.placeholder.subscriptionPricing").waitForExistence(timeout: 5))
    }

    func testSearchFiltersBySKUOrBundleID() {
        launch(scene: "apps")
        XCTAssertTrue(element("sidebar.app.6443000001").waitForExistence(timeout: 10))
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.click()
        search.typeText("receitas")
        XCTAssertTrue(element("sidebar.app.6443000003").waitForExistence(timeout: 5))
        XCTAssertTrue(element("sidebar.app.6443000001").waitForNonExistence(timeout: 5))
    }

    func testSectionPickerSwitchesTheWorkspace() {
        launch(scene: "apps")
        XCTAssertTrue(element("workspace.placeholder.subscriptionPricing").waitForExistence(timeout: 10))
        let picker = element("workspace.sectionPicker")
        XCTAssertTrue(picker.exists)
        picker.radioButtons["Store Page"].click()
        XCTAssertTrue(element("workspace.placeholder.storePage").waitForExistence(timeout: 5))
    }

    func testSelectingAnotherAppShowsItsWorkspace() {
        launch(scene: "apps")
        let wanderlog = element("sidebar.app.6443000004")
        XCTAssertTrue(wanderlog.waitForExistence(timeout: 10))
        wanderlog.click()
        XCTAssertTrue(app.windows.firstMatch.staticTexts["Wanderlog"].waitForExistence(timeout: 5))
    }

    func testEmptyAccountSaysSo() {
        launch(scene: "apps-empty")
        XCTAssertTrue(app.staticTexts["No apps"].waitForExistence(timeout: 10))
    }

    func testLoadFailureOffersARetry() {
        launch(scene: "apps-error")
        XCTAssertTrue(element("sidebar.errorMessage").waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["sidebar.retryButton"].exists)
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launchArguments = ["-AppLocalizerDebugScene", scene]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
