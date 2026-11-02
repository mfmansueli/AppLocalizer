//
//  AutopilotContinuationUITests.swift
//  AppLocalizerUITests
//

import AppKit
import XCTest

/// A Screenshot Autopilot run nobody works on any more says so, with
/// Continue; one that's going doesn't. The DEBUG scenes have no helper, so
/// Continue copies the prompt that picks the run up.
@MainActor
final class AutopilotContinuationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testARunNothingArrivesForSaysSoAndContinues() {
        app.launch(debugScene: "st-stalled")
        let notice = element("autopilot.stall")
        XCTAssertTrue(notice.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: element("autopilot.stall.text")).contains("Nothing has arrived for 85 minutes"), text(of: element("autopilot.stall.text")))
        let stage = element("autopilot.stage.capture")
        XCTAssertTrue(stage.label.contains("Nothing new for a while"), stage.label)
        XCTAssertTrue(text(of: element("autopilot.footer.text")).contains("44 captures left"), text(of: element("autopilot.footer.text")))
        XCTAssertTrue(app.buttons["autopilot.continue"].exists)

        app.buttons["autopilot.stall.continue"].click()
        let note = element("autopilot.stall.note")
        XCTAssertTrue(wait(until: { self.text(of: note).hasPrefix("Copied.") }, timeout: 5), text(of: note))
        let copied = NSPasteboard.general.string(forType: .string) ?? ""
        XCTAssertTrue(copied.hasPrefix("Continue Lumen Journal’s screenshot run from AppLocalizer"), copied)
    }

    func testARunThatsGoingSaysNothing() {
        app.launch(debugScene: "st-cap")
        XCTAssertTrue(element("autopilot.capture").waitForExistence(timeout: 15))
        XCTAssertFalse(element("autopilot.stall").exists)
        XCTAssertFalse(app.buttons["autopilot.continue"].exists)
        XCTAssertFalse(element("autopilot.stage.capture").label.contains("stopped"))
    }

    /// Design after AppLocalizer closed while Claude Code designed: paused,
    /// not stopped (nothing red), and no card spins.
    func testAPausedDesignSaysSoAndNothingSpins() {
        app.launch(debugScene: "st-des-paused")
        let notice = element("autopilot.stall")
        XCTAssertTrue(notice.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: element("autopilot.stall.text")), "Paused when AppLocalizer closed, with 2 directions still to design.")
        let stage = element("autopilot.stage.design")
        XCTAssertTrue(stage.label.contains("Paused · Continue picks it up"), stage.label)
        XCTAssertFalse(stage.label.contains("stopped"), stage.label)
        XCTAssertEqual(text(of: element("autopilot.design.count")), "1 of 3")
        for index in 1...2 {
            let card = text(of: element("autopilot.design.direction.\(index)"))
            XCTAssertTrue(card.contains("Waits for Claude Code"), card)
            XCTAssertFalse(card.contains("designing"), card)
        }
        XCTAssertTrue(text(of: element("autopilot.footer.text")).hasPrefix("Paused when AppLocalizer closed"), text(of: element("autopilot.footer.text")))
        XCTAssertTrue(app.buttons["autopilot.continue"].exists)
    }

    /// Design while the assistant works: the next direction designs, the
    /// one after it is up next, and nothing asks to continue.
    func testADesignThatsGoingShowsWhatsNext() {
        app.launch(debugScene: "st-des")
        XCTAssertTrue(element("autopilot.design").waitForExistence(timeout: 15))
        XCTAssertFalse(element("autopilot.stall").exists)
        XCTAssertFalse(app.buttons["autopilot.continue"].exists)
        let next = text(of: element("autopilot.design.direction.1"))
        XCTAssertTrue(next.contains("Direction 2 · designing…"), next)
        let after = text(of: element("autopilot.design.direction.2"))
        XCTAssertTrue(after.contains("Direction 3 · up next"), after)
    }

    /// Localizing while the assistant writes captions: what it's doing,
    /// missing captions told apart from ones too long, and nothing asking
    /// to continue.
    func testLocalizingSaysWhatClaudeCodeIsWriting() {
        app.launch(debugScene: "st-loc-captions")
        let now = element("autopilot.localize.now")
        XCTAssertTrue(now.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: now).contains("Claude Code is translating 10 captions and shortening 1, in 3 languages."), text(of: now))
        let japanese = text(of: element("autopilot.localize.ja"))
        XCTAssertTrue(japanese.contains("5 captions to translate · Claude Code is writing them"), japanese)
        let german = text(of: element("autopilot.localize.de-DE"))
        XCTAssertTrue(german.contains("1 caption too long · Claude Code is shortening them"), german)
        XCTAssertFalse(element("autopilot.stall").exists)
        let footer = text(of: element("autopilot.footer.text"))
        XCTAssertTrue(footer.hasPrefix("Claude Code writes the captions"), footer)
    }

    private func wait(until condition: @escaping () -> Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.25))
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
