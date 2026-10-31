//
//  AutopilotSheetLayoutUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The Autopilot sheet fits its window: a design project connected by a
/// long link no longer wraps down the stage list and makes the sheet's
/// content taller than the sheet, which cut off its header and its
/// buttons; and long screen names wrap in the plan.
@MainActor
final class AutopilotSheetLayoutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testTheLinkIsShortenedInTheStageList() {
        app.launch(debugScene: "st-plan-link")
        let design = app.buttons["autopilot.stage.design"]
        XCTAssertTrue(design.waitForExistence(timeout: 15))
        XCTAssertTrue(design.label.contains("Claude Design · claude.ai/artifact/KxcpHYis…"), design.label)
        XCTAssertFalse(design.label.contains("org="), design.label)
    }

    func testTheSheetKeepsItsHeaderAndButtonsInAShortWindow() {
        app.launch(debugScene: "st-plan-link")
        let start = app.buttons["autopilot.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        let window = app.windows.firstMatch
        let height = window.frame.height
        // The window keeps its size for the next launch, the other tests'
        // and the app's own: put it back.
        addTeardownBlock { @MainActor [self] in
            resizeWindow(toHeight: height)
        }

        resizeWindow(toHeight: Self.defaultHeight)
        assertTheSheetFits()
        resizeWindow(toHeight: 0)
        XCTAssertLessThan(window.frame.height, Self.defaultHeight - 100, "The window didn't get shorter.")
        assertTheSheetFits()
    }

    func testALongScreenNameWraps() {
        app.launch(debugScene: "st-plan-link")
        let long = element("autopilot.plan.name.1")
        XCTAssertTrue(long.waitForExistence(timeout: 15))
        XCTAssertEqual(long.value as? String, "Customize the background of every phrase")
        XCTAssertGreaterThan(long.frame.height, element("autopilot.plan.name.0").frame.height + 8, "The name wraps instead of being cut")
        let caption = element("autopilot.plan.caption.1")
        XCTAssertEqual(caption.value as? String, "See your week on one calm page")
        XCTAssertGreaterThan(caption.frame.height, element("autopilot.plan.caption.0").frame.height + 8, "The caption wraps too")
    }

    // MARK: - Helpers

    /// The window's `.defaultSize` height.
    private static let defaultHeight: CGFloat = 780

    /// Drags the window's bottom edge, left of the sheet: a sheet taller
    /// than the window hangs over the middle of that edge. It stops at the
    /// window's minimum.
    private func resizeWindow(toHeight height: CGFloat) {
        let window = app.windows.firstMatch
        let delta = height - window.frame.height
        guard abs(delta) > 1 else { return }
        let edge = window.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 1))
        edge.click(forDuration: 0.2, thenDragTo: edge.withOffset(CGVector(dx: 0, dy: delta)))
    }

    /// Close, the stages, Cancel and Start Autopilot are inside the sheet.
    private func assertTheSheetFits(file: StaticString = #filePath, line: UInt = #line) {
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.exists, "No sheet", file: file, line: line)
        let bounds = sheet.frame.insetBy(dx: -1, dy: -1)
        for identifier in ["autopilot.close", "autopilot.cancel", "autopilot.start"] {
            let frame = app.buttons[identifier].frame
            XCTAssertTrue(bounds.contains(frame), "\(identifier) at \(frame) is cut off by the sheet at \(bounds).", file: file, line: line)
        }
        let plan = app.buttons["autopilot.stage.plan"].frame
        XCTAssertTrue(bounds.contains(plan), "The first stage at \(plan) is cut off by the sheet at \(bounds).", file: file, line: line)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
