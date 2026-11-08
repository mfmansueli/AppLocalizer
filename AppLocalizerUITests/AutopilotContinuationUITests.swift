//
//  AutopilotContinuationUITests.swift
//  AppLocalizerUITests
//

import AppKit
import XCTest

/// A Screenshot Autopilot run nobody works on any more says so on Making
/// it, with Continue; one that's going doesn't. The DEBUG scenes have no
/// helper, so Continue copies the prompt that picks the run up.
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
        let footer = text(of: element("autopilot.guided.footer.text"))
        XCTAssertTrue(footer.contains("44 captures left"), footer)
        XCTAssertTrue(app.buttons["autopilot.guided.continue"].exists)

        app.buttons["autopilot.stall.continue"].click()
        let note = element("autopilot.stall.note")
        XCTAssertTrue(wait(until: { self.text(of: note).hasPrefix("Copied.") }, timeout: 5), text(of: note))
        let copied = NSPasteboard.general.string(forType: .string) ?? ""
        XCTAssertTrue(copied.hasPrefix("Continue Lumen Journal’s screenshot run from AppLocalizer"), copied)
    }

    func testARunThatsGoingSaysNothing() {
        app.launch(debugScene: "st-cap")
        XCTAssertTrue(element("autopilot.guided.making.steps").waitForExistence(timeout: 15))
        XCTAssertFalse(element("autopilot.stall").exists)
        XCTAssertFalse(app.buttons["autopilot.guided.continue"].exists)
        let footer = text(of: element("autopilot.guided.footer.text"))
        XCTAssertFalse(footer.contains("isn’t working on this run"), footer)
    }

    /// Design after AppLocalizer closed while Claude Code designed: paused,
    /// not stopped, and no look spins.
    func testAPausedDesignSaysSoAndNothingSpins() {
        app.launch(debugScene: "st-des-paused")
        let notice = element("autopilot.stall")
        XCTAssertTrue(notice.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: element("autopilot.stall.text")), "Paused when AppLocalizer closed, with 2 directions still to design.")
        let line = text(of: element("autopilot.guided.making.line"))
        XCTAssertTrue(line.hasPrefix("1 of 3"), line)
        for index in 1...2 {
            let card = text(of: element("autopilot.guided.making.look.\(index)"))
            XCTAssertTrue(card.contains("Waiting"), card)
            XCTAssertFalse(card.contains("Designing"), card)
        }
        let footer = text(of: element("autopilot.guided.footer.text"))
        XCTAssertTrue(footer.hasPrefix("Paused when AppLocalizer closed"), footer)
        XCTAssertTrue(app.buttons["autopilot.guided.continue"].exists)
    }

    /// Design while the assistant works: the next look designs, the one
    /// after it waits, and nothing asks to continue.
    func testADesignThatsGoingShowsWhatsNext() {
        app.launch(debugScene: "st-des")
        XCTAssertTrue(element("autopilot.guided.making.looks").waitForExistence(timeout: 15))
        XCTAssertFalse(element("autopilot.stall").exists)
        XCTAssertFalse(app.buttons["autopilot.guided.continue"].exists)
        let next = text(of: element("autopilot.guided.making.look.1"))
        XCTAssertTrue(next.contains("Designing"), next)
        let after = text(of: element("autopilot.guided.making.look.2"))
        XCTAssertTrue(after.contains("Waiting"), after)
    }

    /// Localizing while the assistant writes captions: Making it says every
    /// image is checked and who shortens what doesn't fit, and nothing asks
    /// to continue.
    func testLocalizingSaysEveryImageIsChecked() {
        app.launch(debugScene: "st-loc-captions")
        let checking = element("autopilot.guided.making.checking")
        XCTAssertTrue(checking.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: checking).contains("Captions that don’t fit are shortened by Claude Code"), text(of: checking))
        XCTAssertEqual(text(of: element("autopilot.guided.title")), "Localizing and checking")
        XCTAssertFalse(element("autopilot.stall").exists)
        XCTAssertFalse(app.buttons["autopilot.guided.continue"].exists)
        let footer = text(of: element("autopilot.guided.footer.text"))
        XCTAssertTrue(footer.hasPrefix("You can close this window; Autopilot keeps going."), footer)
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
