//
//  AutopilotGuidedUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Autopilot v2, the guided front (board StudioV2), on
/// `StudioDebugGuided`'s scenes: Start… from the page, What to make, Look,
/// Here's the plan, Making it, Choose, Review & push and Sent, plus the
/// Settings choice between Guided and Classic. Each test attaches the
/// window's screenshot.
@MainActor
final class AutopilotGuidedUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Setup

    func testStartOpensWhatToMake() {
        app.launch(debugScene: "v2-home")
        let start = element("studio.autopilot.run")
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        XCTAssertEqual(start.label, "Start…")
        XCTAssertEqual(text(of: element("studio.autopilot.title")), "Autopilot")
        attachScreenshot("Page · Start…")

        start.click()
        XCTAssertTrue(element("autopilot.guided.sheet").waitForExistence(timeout: 10))
        XCTAssertTrue(element("autopilot.guided.make.screenshots").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.guided.step.make").exists)
        XCTAssertTrue(element("autopilot.guided.next").isEnabled)
    }

    func testWhatToMakeTurnsAPartOff() {
        app.launch(debugScene: "v2-make")
        let preview = element("autopilot.guided.make.appPreview")
        XCTAssertTrue(preview.waitForExistence(timeout: 20))
        let footer = element("autopilot.guided.footer.text")
        let before = text(of: footer)
        XCTAssertTrue(before.contains("App Preview"), before)
        attachScreenshot("What to make · everything")

        preview.click()
        XCTAssertTrue(waitUntil { !self.text(of: footer).contains("App Preview") }, text(of: footer))
        XCTAssertTrue(element("autopilot.guided.next").isEnabled)
    }

    func testNothingToMakeCantGoOn() {
        app.launch(debugScene: "v2-make-some")
        let artwork = element("autopilot.guided.make.artwork")
        XCTAssertTrue(artwork.waitForExistence(timeout: 20))
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.isEnabled)
        artwork.click()
        XCTAssertTrue(waitUntil { !next.isEnabled }, "Pick at least one thing")
        XCTAssertTrue(text(of: element("autopilot.guided.footer.text")).contains("Pick at least one thing"))
        attachScreenshot("What to make · nothing")
    }

    func testTheStepsGoForwardAndBack() {
        app.launch(debugScene: "v2-make")
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        next.click()
        XCTAssertTrue(element("autopilot.guided.look.shotStyle.free").waitForExistence(timeout: 5))
        next.click()
        XCTAssertTrue(element("autopilot.guided.plan.timeline").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.guided.start").exists)
        element("autopilot.guided.back").click()
        XCTAssertTrue(element("autopilot.guided.look.shotStyle.free").waitForExistence(timeout: 5))
        element("autopilot.guided.back").click()
        XCTAssertTrue(element("autopilot.guided.make.screenshots").waitForExistence(timeout: 5))
    }

    // MARK: - Look

    func testTemplatesArePickedFromTheFocus() {
        app.launch(debugScene: "v2-look-tpl")
        let pick = element("autopilot.guided.look.template.pick")
        XCTAssertTrue(pick.waitForExistence(timeout: 20))
        XCTAssertEqual(pick.label, "✓ Pick 1 · Remove", "Cinema, the first pick, is in focus")
        XCTAssertTrue(element("autopilot.guided.look.template.tray").exists)
        // At the sheet's narrowest, the header scenes still fit: nothing is cut off on either side.
        let sheet = element("autopilot.guided.sheet")
        for identifier in ["autopilot.guided.look.templateBrowser", "autopilot.guided.look.sceneBrowser"] {
            let frame = element(identifier).frame
            XCTAssertGreaterThanOrEqual(frame.minX, sheet.frame.minX, identifier)
            XCTAssertLessThanOrEqual(frame.maxX, sheet.frame.maxX, identifier)
        }
        attachScreenshot("Look · templates")

        element("autopilot.guided.look.template.highlight").click()
        XCTAssertTrue(waitUntil { pick.label == "Add to My Picks" }, pick.label)
        pick.click()
        XCTAssertTrue(waitUntil { pick.label == "✓ Pick 3 · Remove" }, pick.label)
    }

    func testATemplateIsPreviewedInGerman() {
        app.launch(debugScene: "v2-look-tpl-de")
        let locale = element("autopilot.guided.look.template.locale")
        XCTAssertTrue(locale.waitForExistence(timeout: 20))
        attachScreenshot("Look · templates in German")
    }

    func testOnlyTheHeaderPicksScenes() {
        app.launch(debugScene: "v2-look-art")
        let night = element("autopilot.guided.look.scene.night")
        XCTAssertTrue(night.waitForExistence(timeout: 20))
        XCTAssertFalse(element("autopilot.guided.look.shotStyle.free").exists, "No screenshots to style")
        XCTAssertTrue(element("autopilot.guided.look.scene.pick").exists)
        XCTAssertTrue(element("autopilot.guided.look.note").exists)
        attachScreenshot("Look · header scenes")
    }

    // MARK: - Plan

    func testThePlanNumbersTheStops() {
        app.launch(debugScene: "v2-plan")
        let choose = element("autopilot.guided.plan.row.choose.time")
        XCTAssertTrue(choose.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: choose), "stop 1 of 2")
        XCTAssertEqual(text(of: element("autopilot.guided.plan.row.review.time")), "stop 2 of 2")
        XCTAssertTrue(text(of: element("autopilot.guided.plan.row.design.time")).hasPrefix("about "))
        attachScreenshot("Plan")

        tap("autopilot.guided.plan.choosesForMe")
        XCTAssertTrue(choose.waitForNonExistence(timeout: 5), "Autopilot chooses the look")
        XCTAssertEqual(text(of: element("autopilot.guided.plan.row.review.time")), "the only stop")
    }

    // MARK: - Making it

    func testMakingItSaysWhatsNext() {
        app.launch(debugScene: "v2-run")
        let line = element("autopilot.guided.making.line")
        XCTAssertTrue(line.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: line).contains("captures"), text(of: line))
        let next = element("autopilot.guided.making.next")
        XCTAssertTrue(text(of: next).hasPrefix("Next for you: choose the look, in about "), text(of: next))
        XCTAssertTrue(element("autopilot.guided.cancelRun").exists)
        XCTAssertTrue(element("autopilot.guided.step.making").exists)
        attachScreenshot("Making it · capturing")
    }

    func testTheDesignArrivesLookByLook() {
        app.launch(debugScene: "v2-run-des")
        let line = element("autopilot.guided.making.line")
        XCTAssertTrue(line.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: line).hasPrefix("2 of 3 screenshot looks"), text(of: line))
        attachScreenshot("Making it · designing")
    }

    func testTheClosedSheetLeavesTheProgressOnThePage() {
        app.launch(debugScene: "v2-hidden")
        let title = element("studio.autopilot.title")
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: title), "Autopilot is running")
        XCTAssertTrue(text(of: element("studio.autopilot.text")).hasSuffix("You’ll be notified when it needs you."))
        XCTAssertFalse(element("autopilot.guided.sheet").exists)
        attachScreenshot("Page · running")
    }

    // MARK: - Choose

    func testUseTheseWaitsForALookAndAHeader() {
        app.launch(debugScene: "v2-choose")
        let use = element("autopilot.guided.useChoices")
        XCTAssertTrue(use.waitForExistence(timeout: 20))
        XCTAssertFalse(use.isEnabled, "Nothing chosen yet")
        XCTAssertTrue(element("autopilot.guided.step.choose").exists)
        attachScreenshot("Choose")

        click(app.buttons.matching(identifier: "autopilot.guided.choose.look.use").firstMatch)
        XCTAssertFalse(use.isEnabled, "A header to choose too")
        click(app.buttons.matching(identifier: "autopilot.choose.concept.use").firstMatch)
        XCTAssertTrue(waitUntil { use.isEnabled })
    }

    func testAskingForChangesNamesTheLook() {
        app.launch(debugScene: "v2-choose")
        let ask = app.buttons.matching(identifier: "autopilot.guided.choose.look.ask").firstMatch
        XCTAssertTrue(ask.waitForExistence(timeout: 20))
        ask.click()
        let note = element("autopilot.guided.choose.look.note")
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.click()
        note.typeText("bigger headline")
        element("autopilot.guided.choose.look.send").click()
        XCTAssertTrue(element("autopilot.guided.making.revision").waitForExistence(timeout: 10), "Back at Making it")
    }

    // MARK: - Review & push

    func testPushWaitsForEveryPart() {
        app.launch(debugScene: "v2-review")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.waitForExistence(timeout: 20))
        let push = element("autopilot.guided.push")
        XCTAssertFalse(push.isEnabled)
        attachScreenshot("Review · screenshots")

        for _ in 0..<3 {
            approve.click()
            RunLoop.current.run(until: .now.addingTimeInterval(0.5))
        }
        XCTAssertTrue(waitUntil { push.isEnabled }, "Everything approved")
        push.click()
        XCTAssertTrue(element("autopilot.guided.push.confirm").waitForExistence(timeout: 5))
        attachScreenshot("Review · push?")
    }

    func testTheHeaderTabFollowsTheApprovedScreenshots() {
        app.launch(debugScene: "v2-review-art")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.waitForExistence(timeout: 20))
        XCTAssertEqual(approve.label, "Approve Header and Search")
        attachScreenshot("Review · header and search")
    }

    func testSentSaysWhatWasSent() {
        app.launch(debugScene: "v2-done")
        let title = element("autopilot.guided.done.title")
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: title), "Sent to the App Store")
        XCTAssertTrue(text(of: element("autopilot.guided.done.text")).contains("are on App Store Connect."))
        XCTAssertFalse(element("autopilot.guided.push").exists, "No footer once it's sent")
        attachScreenshot("Sent")
    }

    // MARK: - Settings

    func testSettingsChoosesTheClassicSheet() {
        app.launch(debugScene: "set-general")
        let front = element("settings.autopilotFront")
        XCTAssertTrue(front.waitForExistence(timeout: 20))
        let classic = front.radioButtons["Classic"].exists ? front.radioButtons["Classic"] : front.buttons["Classic"]
        XCTAssertTrue(classic.exists)
        classic.click()
        XCTAssertTrue(waitUntil { classic.isSelected || (classic.value as? Int) == 1 })
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

    private func tap(_ identifier: String) {
        click(element(identifier))
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
