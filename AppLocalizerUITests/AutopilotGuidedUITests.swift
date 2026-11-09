//
//  AutopilotGuidedUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Autopilot v2, the guided front (board StudioV2), on
/// `StudioDebugGuided`'s scenes: Start… from the page, What to make, Look,
/// Here's the plan, Making it, Choose, Review & push and Sent. The guided
/// Autopilot is the only one: Settings no longer offers the classic sheet.
/// Each test attaches the window's screenshot.
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
        app.launch(debugScene: "ap-home")
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
        app.launch(debugScene: "ap-make")
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
        app.launch(debugScene: "ap-make-some")
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
        app.launch(debugScene: "ap-make")
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
        app.launch(debugScene: "ap-look-tpl")
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
        // The preview opens below the fold: it's scrolled into view, its pick
        // button above the footer (a click there went to Next).
        let next = element("autopilot.guided.next")
        XCTAssertTrue(waitUntil { pick.frame.maxY < next.frame.minY }, "\(pick.frame) under the footer at \(next.frame)")
        pick.click()
        XCTAssertTrue(waitUntil { pick.label == "✓ Pick 3 · Remove" }, pick.label)
    }

    func testATemplateIsPreviewedInGerman() {
        app.launch(debugScene: "ap-look-tpl-de")
        let locale = element("autopilot.guided.look.template.locale")
        XCTAssertTrue(locale.waitForExistence(timeout: 20))
        attachScreenshot("Look · templates in German")
    }

    func testATemplateIsPreviewedOnEveryDeviceTheAppShipsOn() {
        app.launch(debugScene: "ap-look-devices")
        let size = element("autopilot.guided.look.template.size")
        XCTAssertTrue(size.waitForExistence(timeout: 20))
        for key in ["iphone", "ipad", "iphone_duo", "mac", "vision", "watch"] {
            XCTAssertTrue(element("autopilot.guided.look.template.device.\(key)").exists, key)
        }
        XCTAssertEqual(element("autopilot.guided.look.template.device.mac").label, "Mac +", "Lumen runs on Mac, but the run doesn't make it")
        XCTAssertEqual(element("autopilot.guided.look.template.device.ipad").label, "iPad")
        let note = element("autopilot.guided.look.template.note")
        reveal(note)
        XCTAssertTrue(waitUntil { self.text(of: size).hasPrefix("iPad 13″") }, text(of: size))
        XCTAssertTrue(text(of: note).contains("5 of 6 devices in this run · + means not in this run"), text(of: note))
        XCTAssertTrue(element("autopilot.guided.look.template.shot.4").exists, "Five iPad screens")
        XCTAssertFalse(element("autopilot.guided.look.template.notInRun").exists, "iPad is in the run")
        attachScreenshot("Look · Arcade on iPad in German")

        tap("autopilot.guided.look.template.device.mac")
        XCTAssertTrue(waitUntil { self.text(of: size).hasPrefix("Mac · 2880 × 1800") }, text(of: size))
        XCTAssertTrue(element("autopilot.guided.look.template.notInRun").waitForExistence(timeout: 5), "Only a preview")
        XCTAssertTrue(element("autopilot.guided.look.template.shot.4").exists, "Five MacBook screenshots")
        attachScreenshot("Look · Arcade on a MacBook")

        tap("autopilot.guided.look.template.device.watch")
        XCTAssertTrue(waitUntil { self.text(of: note).contains("no template is applied") }, text(of: note))
        XCTAssertFalse(element("autopilot.guided.look.template.notInRun").exists, "Apple Watch is in the run")
        attachScreenshot("Look · Apple Watch, bare screens")

        tap("autopilot.guided.look.template.device.vision")
        XCTAssertTrue(waitUntil { self.text(of: size).hasPrefix("Apple Vision Pro") }, text(of: size))
        XCTAssertTrue(element("autopilot.guided.look.template.shot.2").exists, "Three windows")
        XCTAssertFalse(element("autopilot.guided.look.template.shot.3").exists)
    }

    func testMacIsAddedToTheRunFromItsPreview() {
        app.launch(debugScene: "ap-look-mac")
        let banner = element("autopilot.guided.look.template.notInRun")
        XCTAssertTrue(banner.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: banner).hasPrefix("Mac isn’t in this run yet, so this is only a preview."), text(of: banner))
        let size = element("autopilot.guided.look.template.size")
        XCTAssertTrue(text(of: size).hasPrefix("Mac · 2880 × 1800"), text(of: size))
        let note = element("autopilot.guided.look.template.note")
        reveal(note)
        XCTAssertTrue(text(of: note).hasPrefix("Mac App Store screenshots, 16:10: Lumen Journal’s Mac app on a MacBook"), text(of: note))
        attachScreenshot("Look · Mac, not in the run")

        let add = element("autopilot.guided.look.template.addDevice")
        XCTAssertEqual(add.label, "Add Mac to the Run")
        click(add)
        XCTAssertTrue(banner.waitForNonExistence(timeout: 5), "In the run now")
        let mac = element("autopilot.guided.look.template.device.mac")
        XCTAssertTrue(waitUntil { mac.label == "Mac" }, mac.label)
        XCTAssertTrue(mac.isSelected, "The preview stays on Mac")
        XCTAssertFalse(text(of: note).contains("devices in this run"), "Every device is in the run")
        attachScreenshot("Look · Mac added to the run")
    }

    func testAScreenshotOpensLargerAndSwitchesLanguageInPlace() {
        app.launch(debugScene: "ap-look-tpl")
        let shot = element("autopilot.guided.look.template.shot.2")
        XCTAssertTrue(shot.waitForExistence(timeout: 20))
        XCTAssertFalse(element("autopilot.guided.look.template.device.vision").exists, "Only the devices Lumen ships on")
        XCTAssertFalse(element("autopilot.guided.look.template.device.mac").exists, "No Mac app, so no Mac")
        XCTAssertTrue(element("autopilot.guided.look.template.device.iphone_duo").exists)
        click(shot)
        let viewer = element("studio.viewer")
        XCTAssertTrue(viewer.waitForExistence(timeout: 5))
        let count = element("studio.viewer.count")
        let title = element("studio.viewer.title")
        let subtitle = element("studio.viewer.subtitle")
        XCTAssertEqual(text(of: count), "3 of 5")
        XCTAssertTrue(text(of: title).hasPrefix("Cinema · 3 · "), text(of: title))
        XCTAssertTrue(text(of: subtitle).hasPrefix("iPhone 6.9″ · 1320 × 2868 · English"), text(of: subtitle))

        element("studio.viewer.language.de-DE").click()
        XCTAssertTrue(waitUntil { self.text(of: subtitle).hasSuffix("German") }, text(of: subtitle))
        XCTAssertEqual(text(of: count), "3 of 5", "The same screen, in German")
        element("studio.viewer.next").click()
        XCTAssertTrue(waitUntil { self.text(of: count) == "4 of 5" }, text(of: count))
        attachScreenshot("Viewer · Cinema in German")

        element("studio.viewer.close").click()
        XCTAssertTrue(viewer.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.guided.look.template.locale.de-DE").isSelected, "The preview follows the viewer's language")
    }

    func testArcadeIsMarkedNew() {
        app.launch(debugScene: "ap-look-arcade")
        let arcade = element("autopilot.guided.look.template.arcade")
        XCTAssertTrue(arcade.waitForExistence(timeout: 20))
        XCTAssertTrue(arcade.label.hasSuffix("new"), arcade.label)
        XCTAssertFalse(element("autopilot.guided.look.template.cinema").label.hasSuffix("new"))
        XCTAssertEqual(text(of: element("autopilot.guided.look.template.focusName")), "Arcade")
        attachScreenshot("Look · Arcade, new")
    }

    func testOnlyTheHeaderPicksScenes() {
        app.launch(debugScene: "ap-look-art")
        let night = element("autopilot.guided.look.scene.night")
        XCTAssertTrue(night.waitForExistence(timeout: 20))
        XCTAssertFalse(element("autopilot.guided.look.shotStyle.free").exists, "No screenshots to style")
        XCTAssertTrue(element("autopilot.guided.look.scene.pick").exists)
        XCTAssertTrue(element("autopilot.guided.look.note").exists)
        attachScreenshot("Look · header scenes")

        // A clicked scene's preview, its pick button at the bottom, comes into
        // view above the footer, and adding it works.
        element("autopilot.guided.look.scene.horizon").click()
        let pick = element("autopilot.guided.look.scene.pick")
        XCTAssertTrue(waitUntil { pick.label == "Replace Pick 3 With This" }, pick.label)
        let next = element("autopilot.guided.next")
        XCTAssertTrue(waitUntil { pick.frame.maxY < next.frame.minY }, "\(pick.frame) under the footer at \(next.frame)")
        pick.click()
        XCTAssertTrue(waitUntil { pick.label == "✓ Pick 3 · Remove" }, pick.label)
    }

    // MARK: - Plan

    func testThePlanNumbersTheStops() {
        app.launch(debugScene: "ap-plan")
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
        app.launch(debugScene: "ap-run")
        let line = element("autopilot.guided.making.line")
        XCTAssertTrue(line.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: line).contains("captures"), text(of: line))
        let next = element("autopilot.guided.making.next")
        XCTAssertTrue(text(of: next).hasPrefix("Next for you: choose the look, in about "), text(of: next))
        XCTAssertTrue(element("autopilot.guided.cancelRun").exists)
        XCTAssertTrue(element("autopilot.guided.step.making").exists)
        attachScreenshot("Making it · capturing")
    }

    func testCancelRunAsksWhileCapturing() {
        app.launch(debugScene: "ap-run")
        let cancel = element("autopilot.guided.cancelRun")
        XCTAssertTrue(cancel.waitForExistence(timeout: 20))
        cancel.click()
        let keep = app.buttons["autopilot.cancelRun.keep"]
        XCTAssertTrue(keep.waitForExistence(timeout: 5), "Asks first")
        keep.click()
        XCTAssertTrue(element("autopilot.guided.making.line").waitForExistence(timeout: 5), "Still capturing")
    }

    func testTheDesignArrivesLookByLook() {
        app.launch(debugScene: "ap-run-des")
        let line = element("autopilot.guided.making.line")
        XCTAssertTrue(line.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: line).hasPrefix("2 of 3 screenshot looks"), text(of: line))
        attachScreenshot("Making it · designing")
    }

    func testTheClosedSheetLeavesTheProgressOnThePage() {
        app.launch(debugScene: "ap-hidden")
        let title = element("studio.autopilot.title")
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: title), "Autopilot is running")
        XCTAssertTrue(text(of: element("studio.autopilot.text")).hasSuffix("You’ll be notified when it needs you."))
        XCTAssertFalse(element("autopilot.guided.sheet").exists)
        attachScreenshot("Page · running")
    }

    // MARK: - Choose

    func testUseTheseWaitsForALookAndAHeader() {
        app.launch(debugScene: "ap-choose")
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
        app.launch(debugScene: "ap-choose")
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
        app.launch(debugScene: "ap-review")
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
        app.launch(debugScene: "ap-review-art")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.waitForExistence(timeout: 20))
        XCTAssertEqual(approve.label, "Approve Header and Search")
        attachScreenshot("Review · header and search")
    }

    func testSentSaysWhatWasSent() {
        app.launch(debugScene: "ap-done")
        let title = element("autopilot.guided.done.title")
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: title), "Sent to the App Store")
        XCTAssertTrue(text(of: element("autopilot.guided.done.text")).contains("are on App Store Connect."))
        XCTAssertFalse(element("autopilot.guided.push").exists, "No footer once it's sent")
        attachScreenshot("Sent")
    }

    // MARK: - Settings

    func testSettingsNoLongerOffersTheClassicSheet() {
        app.launch(debugScene: "set-general")
        XCTAssertTrue(element("settings.pushConfirmation").waitForExistence(timeout: 20), "General settings are open")
        XCTAssertFalse(element("settings.autopilotFront").exists, "No Guided / Classic choice")
        XCTAssertFalse(app.radioButtons["Classic"].exists)
        attachScreenshot("General settings")
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
