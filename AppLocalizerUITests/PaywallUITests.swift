//
//  PaywallUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// AppLocalizer Pro's paywall, in Free (`-AppLocalizerPro free`, a store
/// that charges nothing): the Pro button, the paywall from Accept All
/// Languages with the person's numbers, the plans, Compare Free and Pro,
/// and buying, which ends on a button that finishes what they started.
@MainActor
final class PaywallUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// The Store Page with suggestions in several languages, in Free.
    private func launchFree(scene: String = "sp-cc") {
        app.launchArguments = ["-AppLocalizerDebugScene", scene, "-AppLocalizerPro", "free", "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        let value = element.value as? String ?? ""
        return value.isEmpty ? element.label : value
    }

    func testProBuildsHaveNoProButtonAndAcceptAllOpensItsSheet() {
        app.launch(debugScene: "sp-cc")
        let acceptAll = app.buttons["languageBar.acceptAll"]
        XCTAssertTrue(acceptAll.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["workspace.proButton"].exists)
        acceptAll.click()
        XCTAssertTrue(element("acceptAll.all").waitForExistence(timeout: 5))
        XCTAssertFalse(element("paywall.sheet").exists)
    }

    func testAcceptAllLanguagesOpensThePaywallWithThePersonsNumbers() {
        launchFree()
        let acceptAll = app.buttons["languageBar.acceptAll"]
        XCTAssertTrue(acceptAll.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["workspace.proButton"].exists)
        acceptAll.click()

        XCTAssertTrue(element("paywall.context.title").waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: element("paywall.context.title")), "Accept All Languages is part of Pro")
        XCTAssertTrue(text(of: element("paywall.context.detail")).hasPrefix("Accept 13 suggestions in 9 languages in one step."))
        // Yearly with its trial first, and exactly what the button does.
        XCTAssertEqual(app.buttons["paywall.buy"].title, "Start 7-Day Free Trial")
        XCTAssertTrue(text(of: element("paywall.finePrint")).hasPrefix("Free for 7 days, then $59.99 a year. Renews automatically"))
        XCTAssertTrue(element("paywall.restore").exists)
        XCTAssertTrue(element("paywall.terms").exists)

        app.buttons["paywall.plan.monthly"].click()
        XCTAssertEqual(app.buttons["paywall.buy"].title, "Subscribe for $9.99 a Month")
        app.buttons["paywall.plan.lifetime"].click()
        XCTAssertEqual(app.buttons["paywall.buy"].title, "Buy Pro for $149.99")

        // Close is always there, and nothing was accepted.
        app.buttons["paywall.close"].click()
        XCTAssertTrue(element("paywall.sheet").waitForNonExistence(timeout: 5))
        XCTAssertFalse(element("acceptAll.all").exists)
    }

    func testCompareShowsTheSplitAndComesBackToThePlans() {
        launchFree()
        XCTAssertTrue(app.buttons["workspace.proButton"].waitForExistence(timeout: 15))
        app.buttons["workspace.proButton"].click()
        // From the toolbar: the plans, with no card.
        XCTAssertTrue(app.buttons["paywall.buy"].waitForExistence(timeout: 5))
        XCTAssertFalse(element("paywall.context").exists)
        element("paywall.compareButton").click()
        XCTAssertTrue(element("paywall.compare").waitForExistence(timeout: 5))
        app.buttons["paywall.backToPlans"].click()
        XCTAssertTrue(app.buttons["paywall.plan.yearly"].waitForExistence(timeout: 5))
    }

    func testBuyingEndsOnFinishingWhatWasStarted() {
        launchFree()
        let acceptAll = app.buttons["languageBar.acceptAll"]
        XCTAssertTrue(acceptAll.waitForExistence(timeout: 15))
        acceptAll.click()
        XCTAssertTrue(app.buttons["paywall.buy"].waitForExistence(timeout: 5))
        app.buttons["paywall.buy"].click()

        XCTAssertTrue(element("paywall.done.title").waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: element("paywall.done.title")), "Your free trial has started")
        let finish = app.buttons["paywall.done.continue"]
        XCTAssertEqual(finish.title, "Accept 13 Suggestions…")
        finish.click()
        // The sheet Accept All Languages opens, now that it's Pro.
        XCTAssertTrue(element("acceptAll.all").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["workspace.proButton"].exists)
    }
}
