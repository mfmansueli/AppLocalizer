//
//  NewLanguagesUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Languages Lumen's project has and its App Store page doesn't (Polish,
/// Turkish, Hebrew), opened by the new-language DEBUG scenes: the banner and
/// its Undo, a suggested language's card, the languages sheet, Review &
/// Push's "Create the Polish page" and Overview's lines.
@MainActor
final class NewLanguagesUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Store Page

    func testTheBannerAddsEveryLanguageAndUndoTakesThemBack() {
        app.launch(debugScene: "sp-newlang")
        let banner = element("storePage.newLanguages")
        XCTAssertTrue(banner.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: element("storePage.newLanguages.text")), """
        Lumen Journal’s 1.4 build supports 3 more languages than its App Store page: Polish, Turkish, Hebrew. People who use them \
        see the English page.
        """)

        app.buttons["storePage.newLanguages.addAll"].click()
        XCTAssertTrue(banner.waitForNonExistence(timeout: 5))
        XCTAssertEqual(text(of: element("toast.text")), """
        Added Polish, Turkish, Hebrew. The pages are created in App Store Connect when you push; their drafted text is in each tab.
        """)

        app.buttons["toast.undo"].click()
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
    }

    func testASuggestedLanguagesTabOffersToCreateItsPage() {
        app.launch(debugScene: "sp-newlang-tab")
        let card = element("storePage.newLanguage")
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: element("storePage.newLanguage.title")), "Polish isn’t on the App Store yet")
        XCTAssertTrue(text(of: element("storePage.newLanguage.text")).hasSuffix("Claude Code drafted the page below."))
        XCTAssertTrue(element("storePage.editorLocale.new").exists)

        app.buttons["storePage.newLanguage.create"].click()
        XCTAssertTrue(card.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("storePage.newLanguageAdded").waitForExistence(timeout: 5))
    }

    func testNotNowGoesBackToEnglishAndStopsSuggestingIt() {
        app.launch(debugScene: "sp-newlang-tab")
        let card = element("storePage.newLanguage")
        XCTAssertTrue(card.waitForExistence(timeout: 10))

        app.buttons["storePage.newLanguage.notNow"].click()
        XCTAssertTrue(card.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("storePage.newLanguages").waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("storePage.newLanguages.text")).contains("2 more languages than its App Store page: Turkish, Hebrew."))
    }

    func testAnAddedLanguageCanStillBeLeftOut() {
        app.launch(debugScene: "sp-newlang-added")
        let banner = element("storePage.newLanguageAdded")
        XCTAssertTrue(banner.waitForExistence(timeout: 10))

        element("storePage.newLanguageAdded.remove").click()
        XCTAssertTrue(banner.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("storePage.newLanguage").waitForExistence(timeout: 5))
    }

    func testTheSheetAddsTheCheckedLanguages() {
        app.launch(debugScene: "langs-sheet")
        let sheet = element("storePage.languagesSheet")
        XCTAssertTrue(sheet.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: element("storePage.languagesSheet.drafted.pl")).hasPrefix("Claude Code drafted 6 fields"))
        let add = app.buttons["storePage.languagesSheet.add"]
        XCTAssertEqual(add.label, "Add 3 Languages")

        element("storePage.languagesSheet.toggle.tr").click()
        XCTAssertEqual(add.label, "Add 2 Languages")
        add.click()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))
        XCTAssertTrue(text(of: element("toast.text")).hasPrefix("Added Polish, Hebrew."))
    }

    // MARK: - Review & Push and Overview

    func testReviewShowsThePageWithItsFields() {
        app.launch(debugScene: "review-newlang")
        let creation = element("review.creation.storePage.6450000001.pl")
        XCTAssertTrue(creation.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: element("review.creation.storePage.6450000001.pl.title")), "Create the Polish page")
        XCTAssertEqual(
            text(of: element("review.creation.storePage.6450000001.pl.detail")),
            "A new App Store language for Lumen Journal, with the text below"
        )
        XCTAssertTrue(element("review.creation.storePage.6450000001.pl.name").exists)
        XCTAssertTrue(element("review.creation.storePage.6450000001.pl.marketingUrl").exists)
    }

    func testOverviewNamesTheNewLanguages() {
        app.launch(debugScene: "ov-newlang")
        let line = element("overview.suggestionsCard.newLanguages")
        XCTAssertTrue(line.waitForExistence(timeout: 10))
        // Each line is one element: "New languages, Polish, Turkish, Hebrew".
        XCTAssertEqual(text(of: line), "New languages, Polish, Turkish, Hebrew")
        XCTAssertEqual(text(of: element("overview.storePageCard.languages")), "Languages, 10 · 3 more in the app")
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }
}
