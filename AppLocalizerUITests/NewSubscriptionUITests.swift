//
//  NewSubscriptionUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Create Subscription from Pricing's empty state, in the DEBUG scene
/// `pricing-nosubs` (Quiet Timer sells nothing; nothing leaves the Mac).
@MainActor
final class NewSubscriptionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testCreatingASubscriptionQueuesItForReview() {
        app.launch(debugScene: "pricing-nosubs")
        let create = app.buttons["pricing.createSubscription"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["pricing.newSubscription.ask"].exists)
        let before = reviewCount()
        create.click()

        XCTAssertTrue(element("pricing.newSubscription").waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: app.textFields["pricing.newSubscription.productID"]), "dev.northpier.quiet.premium.monthly")

        // Add without a description or price: both are named, nothing is
        // queued, and the cursor goes to the first, scrolled into view
        // below the sheet's fold.
        let add = app.buttons["pricing.newSubscription.add"]
        add.click()
        XCTAssertTrue(element("pricing.newSubscription.description.problem").waitForExistence(timeout: 5))
        XCTAssertTrue(element("pricing.newSubscription.price.problem").exists)
        let description = app.textFields["pricing.newSubscription.description"]
        XCTAssertTrue(waitForFocus(on: description))
        description.typeText("Every sound and timer")

        // Then the price, the one problem left.
        add.click()
        let price = app.textFields["pricing.newSubscription.price"]
        XCTAssertTrue(waitForFocus(on: price))
        price.typeText("2.99")
        add.click()

        XCTAssertTrue(element("pricing.newSubscription").waitForNonExistence(timeout: 5))
        let row = element("pricing.newSubscriptions.subscriptionSetup.6450000006.dev.northpier.quiet.premium.monthly")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(reviewCount(), before + 1)

        app.buttons["pricing.newSubscriptions.review"].click()
        XCTAssertTrue(element("review.sheet").waitForExistence(timeout: 10))
        XCTAssertTrue(element("review.creation.subscriptionSetup.6450000006.dev.northpier.quiet.premium.monthly").waitForExistence(timeout: 5))
    }

    /// Whether `element` gets the keyboard focus within a few seconds.
    private func waitForFocus(on element: XCUIElement) -> Bool {
        let focused = NSPredicate(format: "hasKeyboardFocus == true")
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: focused, object: element)], timeout: 5) == .completed
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
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
}
