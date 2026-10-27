//
//  StorePageUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Store Page through its DEBUG scenes (`StorePageDebugScenes`, Lumen
/// Journal's sample listing; nothing leaves the Mac): the coverage grid
/// opening the editor, edits and limits, Find and Replace, the import diff,
/// translation suggestions, and the states without a version or with an
/// error.
@MainActor
final class StorePageUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testACoverageCellOpensTheEditorAtThatField() {
        launch(scene: "store-coverage")
        let cell = element("storePage.cell.de-DE.subtitle")
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        cell.click()
        XCTAssertTrue(element("storePage.editor").waitForExistence(timeout: 5))
        let counter = element("storePage.counter.subtitle")
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        XCTAssertTrue(counter.label.hasPrefix("Over the limit"), counter.label)
    }

    func testTheEditorBlocksAnInvalidURLAndALongSubtitle() {
        launch(scene: "store-editor")
        XCTAssertTrue(element("storePage.editor").waitForExistence(timeout: 15))
        XCTAssertTrue(element("storePage.fieldError.subtitle").exists)
        XCTAssertTrue(element("storePage.fieldError.supportUrl").exists)
    }

    func testEditingAFieldQueuesAChange() {
        launch(scene: "store-coverage")
        let cell = element("storePage.cell.fr-FR.name")
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        let before = reviewCount()
        cell.click()
        let name = element("storePage.input.name")
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.click()
        name.typeKey("a", modifierFlags: .command)
        name.typeText("Lumen : journal")
        XCTAssertTrue(element("storePage.notPushed.name").waitForExistence(timeout: 5))
        XCTAssertTrue(waitForReviewCount(before + 1))
    }

    func testFindAndReplaceChangesEveryMatch() {
        launch(scene: "store-find")
        XCTAssertTrue(element("storePage.findSheet").waitForExistence(timeout: 15))
        let count = element("storePage.find.count")
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        let matches = Int(text(of: count).prefix { $0.isNumber }) ?? 0
        XCTAssertGreaterThan(matches, 0, text(of: count))
        let before = reviewCount()

        app.buttons["storePage.find.replaceAll"].click()
        XCTAssertTrue(element("storePage.findSheet").waitForNonExistence(timeout: 5))
        XCTAssertTrue(notice(startingWith: "Replaced in").waitForExistence(timeout: 5))
        XCTAssertGreaterThan(reviewCount(), before)
    }

    func testAnImportShowsItsChangesBeforeApplying() {
        launch(scene: "store-import")
        XCTAssertTrue(element("storePage.importSheet").waitForExistence(timeout: 15))
        XCTAssertFalse(text(of: element("storePage.import.summary")).isEmpty)
        let before = reviewCount()

        app.buttons["storePage.import.apply"].click()
        XCTAssertTrue(element("storePage.importSheet").waitForNonExistence(timeout: 5))
        XCTAssertTrue(notice(startingWith: "Imported").waitForExistence(timeout: 5))
        XCTAssertGreaterThan(reviewCount(), before)
    }

    func testAcceptedSuggestionsGoToReview() {
        launch(scene: "store-suggestions")
        let acceptAll = app.buttons["storePage.suggestions.acceptAll"]
        XCTAssertTrue(acceptAll.waitForExistence(timeout: 20))
        waitUntilEnabled(acceptAll)
        let before = reviewCount()

        acceptAll.click()
        app.buttons["storePage.suggestions.done"].click()
        XCTAssertTrue(element("storePage.suggestions").waitForNonExistence(timeout: 5))
        XCTAssertGreaterThan(reviewCount(), before)
    }

    func testWithoutAnEditableVersionTheLiveOneIsReadOnly() {
        launch(scene: "store-noversion")
        XCTAssertTrue(element("storePage.noVersion").waitForExistence(timeout: 15))
        app.buttons["storePage.viewLiveVersion"].click()
        XCTAssertTrue(element("storePage.readOnly").waitForExistence(timeout: 5))
    }

    func testARateLimitOffersToTryAgain() {
        launch(scene: "store-ratelimited")
        XCTAssertTrue(element("storePage.loadError").waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["storePage.retry"].exists)
    }

    func testInAppTextsListEachLocale() {
        launch(scene: "store-iap")
        XCTAssertTrue(element("storePage.inAppTexts").waitForExistence(timeout: 15))
        XCTAssertTrue(element("storePage.inAppRow.en-US").waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// A static text's string is its value on macOS; a button's is its label.
    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    /// The notice banner's text, e.g. "Replaced in 4 fields."
    private func notice(startingWith prefix: String) -> XCUIElement {
        element("storePage.notice").staticTexts
            .matching(NSPredicate(format: "value BEGINSWITH %@ OR label BEGINSWITH %@", prefix, prefix))
            .firstMatch
    }

    /// The number on Review & Push, from "N pending changes".
    private func reviewCount() -> Int {
        let value = app.buttons["workspace.reviewPushButton"].value as? String ?? ""
        return Int(value.prefix { $0.isNumber }) ?? 0
    }

    private func waitForReviewCount(_ count: Int) -> Bool {
        let predicate = NSPredicate { _, _ in self.reviewCount() == count }
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 5) == .completed
    }

    private func waitUntilEnabled(_ element: XCUIElement) {
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: element)
        wait(for: [enabled], timeout: 20)
    }
}
