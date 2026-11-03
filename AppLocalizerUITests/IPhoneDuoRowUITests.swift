//
//  IPhoneDuoRowUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The plan's iPhone Duo row (board 30), on `StudioDebugDuoStates`'
/// scenes: inner display, cover display or both, side by side or
/// separate, each with its note; and the side-by-side screenshot full
/// size.
@MainActor
final class IPhoneDuoRowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testEachChoiceSaysWhatItMakes() {
        app.launch(debugScene: "st-plan-duo-pair")
        let note = element("autopilot.plan.duoNote")
        XCTAssertTrue(note.waitForExistence(timeout: 20))
        reveal(note)
        XCTAssertTrue(text(of: note).hasPrefix("Each screenshot shows the Duo unfolded with the folded cover beside it: "), text(of: note))
        XCTAssertTrue(text(of: note).hasSuffix(" per language, both states in one image."), text(of: note))
        XCTAssertTrue(element("autopilot.plan.duoScreens.both").isSelected)
        XCTAssertTrue(element("autopilot.plan.duoBoth.sideBySide").isSelected)
        attachScreenshot("Plan · iPhone Duo side by side")

        tap("autopilot.plan.duoBoth.separate")
        XCTAssertTrue(waitUntil { self.text(of: note).hasPrefix("Each screen unfolded, then folded: ") }, text(of: note))
        XCTAssertTrue(element("autopilot.plan.duoBoth.separate").isSelected)

        tap("autopilot.plan.duoScreens.cover")
        XCTAssertTrue(waitUntil { self.text(of: note).hasPrefix("Folded: the app on the cover display, placed on the 2007 × 2853 canvas.") })
        XCTAssertFalse(element("autopilot.plan.duoBoth").exists, "Only both has a way to show them")

        tap("autopilot.plan.duoScreens.inner")
        XCTAssertTrue(waitUntil {
            self.text(of: note) == "Unfolded, as Apple requires: the inner display at 2007 × 2853. AppLocalizer opens the Duo in Device Hub for each capture."
        }, text(of: note))
        attachScreenshot("Plan · iPhone Duo inner")
    }

    func testTheSideBySideScreenshotOpensFullSize() {
        app.launch(debugScene: "st-lb-duo")
        let title = element("studio.viewer.title")
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        let subtitle = text(of: element("studio.viewer.subtitle"))
        XCTAssertTrue(subtitle.contains("iPhone Duo"), subtitle)
        XCTAssertTrue(subtitle.contains(" · inner and cover, side by side"), subtitle)
        attachScreenshot("Viewer · iPhone Duo side by side")
    }

    // MARK: - Helpers

    /// Scrolls the plan until `target` is inside what it shows.
    private func reveal(_ target: XCUIElement) {
        let plan = element("autopilot.plan")
        var tries = 0
        while !(target.frame.minY >= plan.frame.minY && target.frame.maxY <= plan.frame.maxY), tries < 12 {
            plan.scroll(byDeltaX: 0, deltaY: target.frame.minY < plan.frame.minY ? 200 : -200)
            tries += 1
        }
    }

    private func tap(_ identifier: String) {
        let target = element(identifier)
        reveal(target)
        target.click()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        return condition()
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
