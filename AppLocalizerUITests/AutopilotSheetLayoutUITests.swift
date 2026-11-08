//
//  AutopilotSheetLayoutUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The Autopilot sheet fits its window: a design project connected by a
/// long link is shortened in the plan, the sheet keeps its header, steps
/// and buttons in a short window, and long screen names wrap in the
/// plan's screens.
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

    func testTheLinkIsShortenedInThePlan() {
        app.launch(debugScene: "st-plan-link")
        goToThePlan()
        let design = element("autopilot.guided.plan.design")
        XCTAssertTrue(design.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: design).contains("Claude Design · claude.ai/artifact/KxcpHYis…"), text(of: design))
        XCTAssertFalse(text(of: design).contains("org="), text(of: design))
    }

    func testTheSheetKeepsItsHeaderAndButtonsInAShortWindow() {
        app.launch(debugScene: "st-plan-link")
        goToThePlan()
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
        goToThePlan()
        showScreens()
        let long = element("autopilot.plan.name.1")
        XCTAssertTrue(long.waitForExistence(timeout: 5))
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

    /// Cancel, the first step, Back and Start are inside the sheet.
    private func assertTheSheetFits(file: StaticString = #filePath, line: UInt = #line) {
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.exists, "No sheet", file: file, line: line)
        let bounds = sheet.frame.insetBy(dx: -1, dy: -1)
        for identifier in ["autopilot.guided.cancel", "autopilot.guided.step.make", "autopilot.guided.back", "autopilot.guided.start"] {
            let frame = element(identifier).frame
            XCTAssertTrue(bounds.contains(frame), "\(identifier) at \(frame) is cut off by the sheet at \(bounds).", file: file, line: line)
        }
    }

    /// The sheet opens a planned run at What to make: on to the plan.
    private func goToThePlan() {
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        next.click()
        XCTAssertTrue(element("autopilot.guided.back").waitForExistence(timeout: 5), "At Look")
        element("autopilot.guided.next").click()
        XCTAssertTrue(element("autopilot.guided.start").waitForExistence(timeout: 5), "At the plan")
    }

    /// The plan's screens are folded under the capture line: shows them.
    private func showScreens() {
        let toggle = element("autopilot.guided.plan.screens.toggle")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        if (toggle.value as? String) != "Shown" { toggle.click() }
        XCTAssertTrue(element("autopilot.plan.addScreen").waitForExistence(timeout: 5), "The screens are shown")
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
