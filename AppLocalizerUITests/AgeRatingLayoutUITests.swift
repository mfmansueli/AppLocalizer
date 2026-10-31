//
//  AgeRatingLayoutUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Age Rating fits its window: the suggestion bar wraps and the rating
/// preview goes above the questions rather than making the page wider than
/// the window, which pushed the sidebar and the page column off the
/// window's left edge and the preview off its right one.
@MainActor
final class AgeRatingLayoutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testTheDefaultWindowFitsThePageBeforeAndAfterAcceptAll() {
        app.launch(debugScene: "in-age")
        let preview = element("appInformation.age.preview")
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        resizeWindow(toWidth: Self.defaultWidth)
        assertEverythingFits()
        XCTAssertGreaterThan(preview.frame.minX, element("suggestions.bar").frame.maxX, "The preview sits beside the questions at the default size.")

        app.buttons["suggestions.acceptAll"].click()
        XCTAssertTrue(element("toast.text").waitForExistence(timeout: 5))
        assertEverythingFits()
        XCTAssertGreaterThan(preview.frame.minX, element("suggestions.bar").frame.maxX)
    }

    func testANarrowWindowPutsThePreviewAboveTheQuestions() {
        app.launch(debugScene: "in-age-done")
        let preview = element("appInformation.age.preview")
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        resizeWindow(toWidth: Self.defaultWidth)
        // The window keeps its size for the next launch, the other tests'
        // and the app's own: put it back.
        addTeardownBlock { @MainActor [self] in
            resizeWindow(toWidth: Self.defaultWidth)
        }

        resizeWindow(toWidth: Self.defaultWidth - 500)
        XCTAssertLessThan(app.windows.firstMatch.frame.width, Self.defaultWidth - 200, "The window didn't get narrower.")

        assertEverythingFits()
        XCTAssertLessThan(preview.frame.maxY, element("suggestions.bar").frame.minY, "The preview goes above the questions.")
    }

    // MARK: - Helpers

    /// The window's `.defaultSize` width.
    private static let defaultWidth: CGFloat = 1200

    /// Drags the window's right edge; it stops at the window's minimum.
    private func resizeWindow(toWidth width: CGFloat) {
        let window = app.windows.firstMatch
        let delta = width - window.frame.width
        guard abs(delta) > 1 else { return }
        let edge = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
        edge.click(forDuration: 0.2, thenDragTo: edge.withOffset(CGVector(dx: delta, dy: 0)))
    }

    /// The sidebar, the page column, the bar with its buttons and the
    /// preview are inside the window, side by side, none under another.
    private func assertEverythingFits(file: StaticString = #filePath, line: UInt = #line) {
        let window = app.windows.firstMatch.frame.insetBy(dx: -1, dy: -1)
        let sidebar = element("sidebar.appList").frame
        let pageColumn = element("appInformation.pageColumn").frame
        for identifier in ["sidebar.appList", "appInformation.pageColumn", "suggestions.bar", "suggestions.acceptAll", "appInformation.age.preview"] {
            let frame = element(identifier).frame
            XCTAssertTrue(window.minX <= frame.minX && frame.maxX <= window.maxX, "\(identifier) at \(frame) spills out of the window at \(window).", file: file, line: line)
        }
        XCTAssertGreaterThanOrEqual(pageColumn.minX, sidebar.maxX - 1, "The page column slid under the sidebar.", file: file, line: line)
        XCTAssertGreaterThanOrEqual(element("suggestions.bar").frame.minX, pageColumn.maxX, "The page slid under the page column.", file: file, line: line)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
