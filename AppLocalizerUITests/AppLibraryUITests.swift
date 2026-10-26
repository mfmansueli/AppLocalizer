//
//  AppLibraryUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The main window's app library, toolbar and overview, driven through the
/// DEBUG scenes `apps`, `overview-keep`, `apps-empty`, `apps-error` and
/// `lib-loading` (the sample Northpier Studio account from `DebugFixtures`).
@MainActor
final class AppLibraryUITests: XCTestCase {
    private var app: XCUIApplication!

    private enum AppID {
        static let lumen = "6450000001"
        static let habitat = "6450000002"
        static let tempo = "6450000003"
        static let fieldnote = "6450000004"
        static let parcel = "6450000005"
        static let quiet = "6450000006"
    }

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testSidebarListsTheAccountsAppsAndShowsTheSelectedOverview() {
        launch(scene: "apps")
        for id in [AppID.lumen, AppID.habitat, AppID.tempo, AppID.fieldnote, AppID.parcel, AppID.quiet] {
            XCTAssertTrue(element("sidebar.app.\(id)").waitForExistence(timeout: 10), "missing app \(id)")
        }
        XCTAssertTrue(element("workspace.overview").waitForExistence(timeout: 5))
        XCTAssertTrue(element("overview.subscriptionsCard").waitForExistence(timeout: 5))
        XCTAssertTrue(element("overview.storePageCard").exists)
        XCTAssertTrue(element("overview.pendingChangesCard").exists)
    }

    func testAccountSwitcherShowsTheTeam() {
        launch(scene: "apps")
        let switcher = app.menuButtons["sidebar.accountSwitcher"]
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        XCTAssertTrue("\(switcher.title) \(switcher.label)".contains("Northpier Studio"))
    }

    func testSearchFiltersBySKUOrBundleID() {
        launch(scene: "apps")
        XCTAssertTrue(element("sidebar.app.\(AppID.lumen)").waitForExistence(timeout: 10))
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.click()
        search.typeText("fnote")
        XCTAssertTrue(element("sidebar.app.\(AppID.fieldnote)").waitForExistence(timeout: 5))
        XCTAssertTrue(element("sidebar.app.\(AppID.lumen)").waitForNonExistence(timeout: 5))
    }

    func testSectionPickerSwitchesTheWorkspace() {
        launch(scene: "apps")
        XCTAssertTrue(element("workspace.overview").waitForExistence(timeout: 10))
        let picker = element("workspace.sectionPicker")
        XCTAssertTrue(picker.exists)
        picker.radioButtons["Store Page"].click()
        XCTAssertTrue(element("workspace.storePage").waitForExistence(timeout: 5))
        picker.radioButtons["App Information"].click()
        XCTAssertTrue(element("workspace.appInformation").waitForExistence(timeout: 5))
    }

    func testCommandDigitsSwitchSections() {
        launch(scene: "apps")
        XCTAssertTrue(element("workspace.overview").waitForExistence(timeout: 10))
        app.typeKey("3", modifierFlags: .command)
        XCTAssertTrue(element("workspace.storePage").waitForExistence(timeout: 5))
        app.typeKey("1", modifierFlags: .command)
        XCTAssertTrue(element("workspace.overview").waitForExistence(timeout: 5))
    }

    func testSelectingAnotherAppShowsItsOverview() {
        launch(scene: "apps")
        let parcel = element("sidebar.app.\(AppID.parcel)")
        XCTAssertTrue(parcel.waitForExistence(timeout: 10))
        parcel.click()
        XCTAssertTrue(app.windows.firstMatch.staticTexts["Parcel Pal"].waitForExistence(timeout: 5))
    }

    func testKeepMyPricesOverviewOffersSuggestionsQuietly() {
        launch(scene: "overview-keep")
        XCTAssertTrue(element("overview.showPriceSuggestions").waitForExistence(timeout: 10))
        XCTAssertFalse(element("overview.reviewSuggestions").exists)
    }

    func testReviewAndPushOpensTheReviewSheet() {
        launch(scene: "apps")
        let button = element("workspace.reviewPushButton")
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.click()
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 5))
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

    func testFirstSyncShowsSkeletons() {
        launch(scene: "lib-loading")
        XCTAssertTrue(element("overview.skeleton").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Syncing with App Store Connect…"].exists)
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
