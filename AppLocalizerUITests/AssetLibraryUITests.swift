//
//  AssetLibraryUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The App Asset Library sheet through the `asset-library` DEBUG scene:
/// files on a page can't be picked, Select Unused picks the leftovers, and
/// one confirmation deletes them all.
@MainActor
final class AssetLibraryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testSeveralLeftoversAreDeletedAtOnce() {
        app.launch(debugScene: "asset-library")
        XCTAssertTrue(element("assetLibrary.list").waitForExistence(timeout: 20))
        let status = element("assetLibrary.status")
        XCTAssertTrue(waitFor(status, toContain: "on no page", timeout: 20), text(of: status))
        XCTAssertFalse(element("assetLibrary.check.header-en-US").isEnabled, "A page shows it")
        XCTAssertTrue(text(of: element("assetLibrary.placement.header-old-en-US")).contains("Not on any page"))

        app.buttons["assetLibrary.selectUnused"].click()
        XCTAssertTrue(text(of: element("assetLibrary.selected")).contains("6 selected"), text(of: element("assetLibrary.selected")))
        app.buttons["assetLibrary.delete"].click()
        let confirm = app.buttons["Delete 6 Files"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.click()

        XCTAssertTrue(waitFor(status, toContain: "Deleted 6 files.", timeout: 20), text(of: status))
        XCTAssertFalse(element("assetLibrary.row.header-old-en-US").exists)
        XCTAssertTrue(element("assetLibrary.row.header-en-US").exists, "Files on a page stay")
        let shot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        shot.name = "Asset library after deleting"
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func text(of element: XCUIElement) -> String {
        "\(element.label) \(element.value as? String ?? "")"
    }

    private func waitFor(_ element: XCUIElement, toContain expected: String, timeout: TimeInterval) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if text(of: element).contains(expected) { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        return false
    }
}
