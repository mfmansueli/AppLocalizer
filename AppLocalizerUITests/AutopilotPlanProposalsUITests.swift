//
//  AutopilotPlanProposalsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// What the assistant sent for the plan outside a run, on
/// `StudioDebugPlanProposals`' `ap-plan-sent`: the change waiting at the top
/// of Here's the plan (Accept, Reject), the screen suggested for the set
/// under the screens (Add to Plan), and Remove on the command and the note
/// fixes added. Each test attaches the window's screenshot.
@MainActor
final class AutopilotPlanProposalsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testAcceptingTheChangeTakesItIntoThePlan() {
        app.launch(debugScene: "ap-plan-sent")
        let accept = element("autopilot.plan.change.pc-sent.accept")
        XCTAssertTrue(accept.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: element("autopilot.plan.change.pc-sent.reason")).hasPrefix("1.4 reaches Week"))
        let command = element("autopilot.plan.extraCommand.remove")
        XCTAssertTrue(command.exists, "The command a fix added, before the change removes it")
        attachScreenshot("Plan · sent for this plan")

        click(accept)
        XCTAssertTrue(accept.waitForNonExistence(timeout: 5))
        XCTAssertTrue(command.waitForNonExistence(timeout: 5), "The change removed the fixes' commands")
        XCTAssertTrue(element("autopilot.plan.changes.showScreens").exists, "The suggested screen still waits")
    }

    func testRejectingTheChangeKeepsThePlan() {
        app.launch(debugScene: "ap-plan-sent")
        let reject = element("autopilot.plan.change.pc-sent.reject")
        XCTAssertTrue(reject.waitForExistence(timeout: 20))
        click(reject)
        XCTAssertTrue(reject.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.plan.extraCommand.remove").exists)
    }

    func testTheSuggestedScreenIsAddedFromUnderTheScreens() {
        app.launch(debugScene: "ap-plan-sent")
        let show = element("autopilot.plan.changes.showScreens")
        XCTAssertTrue(show.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: element("autopilot.plan.changes.screens")).contains("1 screen for the set"))
        click(show)
        let add = element("autopilot.plan.suggestion.ps-sent-1.add")
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        attachScreenshot("Plan · My Phrases under the screens")

        click(add)
        XCTAssertTrue(element("autopilot.plan.suggestion.ps-sent-1.added").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.plan.changes.screens").waitForNonExistence(timeout: 5), "Nothing left to add")
    }

    func testTheCommandAndTheNoteFixesAddedCanBeRemoved() {
        app.launch(debugScene: "ap-plan-sent")
        let command = element("autopilot.plan.extraCommand.remove")
        let note = element("autopilot.plan.fixNote.remove")
        XCTAssertTrue(command.waitForExistence(timeout: 20))
        XCTAssertTrue(note.exists)
        attachScreenshot("Plan · simulator options with a command and a note")

        click(command)
        XCTAssertTrue(command.waitForNonExistence(timeout: 5))
        click(note)
        XCTAssertTrue(note.waitForNonExistence(timeout: 5))
    }

    // MARK: - Helpers

    /// Scrolls the step until `target` is above the footer: the content
    /// scrolls under it, so a click on what's below would hit the footer.
    private func reveal(_ target: XCUIElement) {
        let scroll = element("autopilot.guided.sheet").scrollViews.firstMatch
        guard scroll.exists else { return }
        let footer = element("autopilot.guided.footer.text")
        var tries = 0
        while tries < 12 {
            let bottom = min(scroll.frame.maxY, footer.exists ? footer.frame.minY - 12 : scroll.frame.maxY)
            if target.frame.minY >= scroll.frame.minY, target.frame.maxY <= bottom { return }
            scroll.scroll(byDeltaX: 0, deltaY: target.frame.minY < scroll.frame.minY ? 200 : -200)
            tries += 1
        }
    }

    private func click(_ target: XCUIElement) {
        reveal(target)
        target.click()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func text(of element: XCUIElement) -> String {
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
