//
//  PricingUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The Prices tab of Subscription Pricing, driven through the DEBUG scenes in
/// `PricingDebugScenes` (sample prices and price points, simulated App Store
/// Connect; nothing leaves the Mac).
@MainActor
final class PricingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testChoosingAModeInTheFirstVisitSheet() {
        launch(scene: "mode-sheet")
        XCTAssertTrue(element("pricing.modeSheet").waitForExistence(timeout: 10))
        element("pricing.modeSheet.option.showSuggestions").click()
        app.buttons["pricing.modeSheet.continue"].click()
        XCTAssertTrue(element("pricing.modeSheet").waitForNonExistence(timeout: 5))
        XCTAssertTrue(elements(prefixed: "pricing.suggested.").firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: element("pricing.bottomBar.summary")).contains("likely held back by price"))
        XCTAssertTrue(app.buttons["pricing.applyRecommended"].exists)
    }

    func testApplyRecommendedPricesAddsThemToReviewAndPush() {
        launch(scene: "pricing-bulk")
        let apply = app.buttons["pricing.applyRecommended"]
        XCTAssertTrue(apply.waitForExistence(timeout: 10))
        waitUntilEnabled(apply)
        let before = reviewCount()
        apply.click()
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 10))
        XCTAssertGreaterThan(reviewCount(), before)
        XCTAssertTrue(element("review.row.price.6450100002.BRA").exists)
    }

    func testMultiplyingTheSelectedTerritories() {
        launch(scene: "pricing-bulk")
        let count = element("pricing.selectionCount")
        XCTAssertTrue(count.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: count), "4 selected")
        let before = pendingCount()
        element("pricing.more").click()
        let multiply = app.menuItems["Multiply by 0.9"]
        XCTAssertTrue(multiply.waitForExistence(timeout: 5))
        multiply.click()
        let summary = element("pricing.bottomBar.summary")
        let updated = NSPredicate { _, _ in self.pendingCount() == before + 4 }
        wait(for: [XCTNSPredicateExpectation(predicate: updated, object: summary)], timeout: 10)
        XCTAssertTrue(app.buttons["pricing.stepper.up.IND"].exists)
    }

    func testKeepMyPricesStaysReadOnly() {
        launch(scene: "pricing-keep")
        XCTAssertTrue(element("pricing.matrix").waitForExistence(timeout: 10))
        XCTAssertTrue(elements(prefixed: "pricing.row.").firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.links["pricing.showSuggestions"].exists)
        XCTAssertEqual(elements(prefixed: "pricing.stepper.").count, 0)
        XCTAssertEqual(elements(prefixed: "pricing.apply.").count, 0)
        XCTAssertFalse(app.buttons["pricing.applyRecommended"].exists)
        elements(prefixed: "pricing.row.").firstMatch.click()
        XCTAssertFalse(element("pricing.more").exists)
        XCTAssertFalse(element("pricing.selectionCount").exists)
    }

    func testTheProposedPriceOpensItsBreakdown() {
        launch(scene: "pricing-applied")
        let search = element("pricing.search")
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.click()
        search.typeText("Brazil")
        let proposed = app.buttons["pricing.proposed.BRA"]
        XCTAssertTrue(proposed.waitForExistence(timeout: 10))
        proposed.click()
        let popover = element("pricing.breakdownPopover")
        XCTAssertTrue(popover.waitForExistence(timeout: 5))
        app.buttons["pricing.breakdown.done"].click()
        XCTAssertTrue(popover.waitForNonExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func launch(scene: String) {
        app.launchArguments = ["-AppLocalizerDebugScene", scene, "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func elements(prefixed prefix: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
    }

    /// A text element's string: its value on macOS, else its label.
    private func text(of element: XCUIElement) -> String {
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }

    /// The number on Review & Push, from "N pending changes".
    private func reviewCount() -> Int {
        let value = app.buttons["workspace.reviewPushButton"].value as? String ?? ""
        return Int(value.prefix { $0.isNumber }) ?? 0
    }

    /// The product's pending count, from the bottom bar's "… · N pending".
    private func pendingCount() -> Int {
        let summary = text(of: element("pricing.bottomBar.summary"))
        guard let range = summary.range(of: " pending", options: .backwards) else { return -1 }
        let digits = summary[..<range.lowerBound].reversed().prefix { $0.isNumber }
        return Int(String(digits.reversed())) ?? -1
    }

    private func waitUntilEnabled(_ element: XCUIElement) {
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: element)
        wait(for: [enabled], timeout: 10)
    }
}
