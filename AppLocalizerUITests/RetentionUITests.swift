//
//  RetentionUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Pricing → Retention in the DEBUG scene `ret-none` (Lumen Journal without
/// a retention message; nothing leaves the Mac): Create Message opens the
/// editor, the header's counter follows the typing, and the draft is still
/// there after Prices and back.
@MainActor
final class RetentionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testANewMessageCountsItsHeaderAndStaysAfterPrices() {
        app.launch(debugScene: "ret-none")
        // Retention is the pricing section's only child, so its own
        // identifier merges into the section's (the outer one wins): anchor
        // on its intro instead.
        XCTAssertTrue(element("retention.intro").waitForExistence(timeout: 15))
        XCTAssertTrue(element("retention.empty").waitForExistence(timeout: 10))

        element("retention.empty.create").click()
        XCTAssertTrue(element("retention.editor").waitForExistence(timeout: 5))
        XCTAssertTrue(element("retention.preview").exists)
        let header = app.textFields["retention.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        header.click()
        header.typeText("Stay a little longer")
        XCTAssertTrue(counter("retention.headerCount", says: "20"), "The header counter should say 20 of 66")

        element("pricing.page.prices").click()
        XCTAssertTrue(element("retention.editor").waitForNonExistence(timeout: 5))
        element("pricing.page.retention").click()
        XCTAssertTrue(element("retention.editor").waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["retention.header"].value as? String, "Stay a little longer")
        XCTAssertTrue(element("retention.message.draft-1").exists)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    /// The counter's text ("20 / 66") or label ("20 of 66 characters").
    private func counter(_ identifier: String, says count: String) -> Bool {
        let counter = element(identifier)
        let deadline = Date.now.addingTimeInterval(5)
        while Date.now < deadline {
            let words = [counter.label, counter.value as? String ?? ""].joined(separator: " ")
            if words.contains("\(count) / 66") || words.contains("\(count) of 66") { return true }
            RunLoop.current.run(until: Date.now.addingTimeInterval(0.2))
        }
        return false
    }
}
