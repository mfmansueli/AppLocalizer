//
//  AutopilotHeaderConceptsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Header concepts (board 33), on `StudioDebugHeaderStyle`'s scenes: the
/// Look step's header (scene templates or Go freely) and screenshots
/// from gallery templates, Making it's concepts as they arrive, Choose's
/// look and header apart with Use These, a concept and its loop full
/// size, and the header loop on Review & push. Each test attaches the
/// window's screenshot.
@MainActor
final class AutopilotHeaderConceptsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Look

    /// A header-only run from three scene templates: the three are picked,
    /// a fourth replaces the last, and ✕ in My picks takes one out.
    func testTheHeaderStartsFromThreeSceneTemplates() {
        app.launch(debugScene: "st-plan-tpl")
        goToTheLook(showing: "autopilot.guided.look.headerStyle.templates")
        XCTAssertTrue(element("autopilot.guided.look.headerStyle.templates").isSelected)
        let night = element("autopilot.guided.look.scene.night")
        let land = element("autopilot.guided.look.scene.land")
        let window = element("autopilot.guided.look.scene.window")
        let hero = element("autopilot.guided.look.scene.hero")
        XCTAssertTrue(night.label.contains("pick 1"), night.label)
        XCTAssertTrue(land.label.contains("pick 2"), land.label)
        XCTAssertTrue(window.label.contains("pick 3"), window.label)
        XCTAssertFalse(hero.label.contains("pick"), hero.label)
        let pick = element("autopilot.guided.look.scene.pick")
        XCTAssertEqual(pick.label, "✓ Pick 1 · Remove", "Day to Night, the first pick, is previewed")
        attachScreenshot("Look · header from scene templates")

        click(hero)
        XCTAssertTrue(waitUntil { pick.label == "Replace Pick 3 With This" }, pick.label)
        click(pick)
        XCTAssertTrue(waitUntil { hero.label.contains("pick 3") }, hero.label)
        XCTAssertFalse(window.label.contains("pick"), "A fourth replaces the last")

        tap("autopilot.guided.look.scene.tray.remove.2")
        XCTAssertTrue(element("autopilot.guided.look.scene.tray.empty.3").waitForExistence(timeout: 5))
        XCTAssertFalse(land.label.contains("pick"), land.label)
        XCTAssertTrue(hero.label.contains("pick 2"), hero.label)
    }

    /// Going freely: no scenes to pick, the designer gets the person's
    /// words, and scene templates bring the scenes back.
    func testGoingFreelyLeavesTheHeaderToTheDesigner() {
        app.launch(debugScene: "st-plan-free")
        goToTheLook(showing: "autopilot.guided.look.headerFree")
        let free = element("autopilot.guided.look.headerFree")
        XCTAssertTrue(element("autopilot.guided.look.headerStyle.free").isSelected)
        XCTAssertTrue(text(of: free).hasPrefix("Claude Design studies Lumen Journal and proposes 3 concepts of its own"), text(of: free))
        XCTAssertFalse(element("autopilot.guided.look.scene.night").exists, "No scenes to pick")
        XCTAssertEqual(text(of: element("autopilot.guided.look.note")), "Calm, like writing before bed", "The person's words go to the designer")
        attachScreenshot("Look · go freely")

        tap("autopilot.guided.look.headerStyle.templates")
        XCTAssertTrue(element("autopilot.guided.look.scene.night").waitForExistence(timeout: 5))
        XCTAssertFalse(free.exists)
    }

    /// Screenshots from gallery templates: the two picked are numbered,
    /// the style filter narrows the gallery, a third is added from its
    /// preview, ✕ takes one out, and a new look leaves the templates.
    func testTheScreenshotsStartFromGalleryTemplates() {
        app.launch(debugScene: "st-plan-shotstyle")
        goToTheLook(showing: "autopilot.guided.look.templateBrowser")
        XCTAssertTrue(element("autopilot.guided.look.shotStyle.templates").isSelected)
        let cinema = element("autopilot.guided.look.template.cinema")
        let editorial = element("autopilot.guided.look.template.editorial")
        let above = element("autopilot.guided.look.template.above")
        XCTAssertTrue(cinema.label.contains("pick 1"), cinema.label)
        XCTAssertTrue(editorial.label.contains("pick 2"), editorial.label)
        XCTAssertTrue(element("autopilot.guided.look.template.tray.empty.3").exists, "A place for a third")
        attachScreenshot("Look · screenshots from templates")

        let filter = element("autopilot.guided.look.templateBrowser").descendants(matching: .any)["screenshots.gallery.style"]
        reveal(filter)
        filter.radioButtons["Elegant"].click()
        XCTAssertTrue(above.waitForNonExistence(timeout: 5), "Only the elegant ones")
        XCTAssertTrue(cinema.exists, "Cinema is elegant")
        filter.radioButtons["All"].click()
        XCTAssertTrue(above.waitForExistence(timeout: 5))

        click(above)
        let pick = element("autopilot.guided.look.template.pick")
        XCTAssertTrue(waitUntil { pick.label == "Add to My Picks" }, pick.label)
        click(pick)
        XCTAssertTrue(waitUntil { above.label.contains("pick 3") }, above.label)
        XCTAssertFalse(element("autopilot.guided.look.template.tray.empty.3").exists, "Three picked: no place left")

        tap("autopilot.guided.look.template.tray.remove.2")
        XCTAssertTrue(waitUntil { !editorial.label.contains("pick") }, editorial.label)
        XCTAssertTrue(above.label.contains("pick 2"), above.label)

        tap("autopilot.guided.look.shotStyle.free")
        XCTAssertTrue(element("autopilot.guided.look.templateBrowser").waitForNonExistence(timeout: 5), "A new look: no templates to pick")
    }

    // MARK: - Making it

    func testConceptsFillInAsTheyArrive() {
        app.launch(debugScene: "st-des-tpl")
        let concepts = element("autopilot.design.concepts")
        XCTAssertTrue(concepts.waitForExistence(timeout: 20))
        let line = text(of: element("autopilot.guided.making.line"))
        XCTAssertTrue(line.contains("1 of 3 headers"), line)
        XCTAssertTrue(text(of: element("autopilot.design.concept.0")).contains("Moonrise"))
        XCTAssertTrue(text(of: element("autopilot.design.concept.1")).contains("Evening Hills"), "An idea shows before its pages")
        XCTAssertTrue(text(of: element("autopilot.design.concept.2")).contains("Concept 3 · from the Window View template"))
        XCTAssertFalse(element("autopilot.guided.making.looks").exists, "Only the header: no screenshot looks")
        attachScreenshot("Making it · concepts from templates")
    }

    /// Making it while the loops come: the first plays, the others say
    /// they're being animated.
    func testDesignSaysWhichLoopsAreComing() {
        app.launch(debugScene: "st-des-header-loop")
        let second = element("autopilot.design.concept.1")
        XCTAssertTrue(second.waitForExistence(timeout: 20))
        let line = text(of: element("autopilot.guided.making.line"))
        XCTAssertTrue(line.contains("1 of 3 headers"), line)
        XCTAssertTrue(second.label.contains("is animating its 20-second loop"), second.label)
        attachScreenshot("Making it · loops coming")
    }

    // MARK: - Choose

    func testChooseTakesADirectionAndAHeader() {
        app.launch(debugScene: "st-choose-tpl")
        let moonrise = element("autopilot.choose.concept.A")
        XCTAssertTrue(moonrise.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: element("autopilot.guided.title")), "Choose the look")
        let use = element("autopilot.guided.useChoices")
        XCTAssertEqual(use.label, "Use These")
        XCTAssertTrue(use.isEnabled, "A look and a header are chosen")
        let footer = text(of: element("autopilot.guided.footer.text"))
        XCTAssertTrue(footer.hasPrefix("Next, AppLocalizer "), footer)
        attachScreenshot("Choose · a look and a header")

        let evening = element("autopilot.choose.concept.B")
        evening.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch.click()
        XCTAssertTrue(waitUntil { evening.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch.label == "Chosen" })
        let moonriseUse = moonrise.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch
        XCTAssertEqual(moonriseUse.label, "Choose", "One header at a time")
    }

    func testAHeaderOnlyRunWaitsForTheHeader() {
        app.launch(debugScene: "st-choose-free")
        let ink = element("autopilot.choose.concept.A")
        XCTAssertTrue(ink.waitForExistence(timeout: 20))
        let use = element("autopilot.guided.useChoices")
        XCTAssertFalse(use.isEnabled, "No header chosen yet")
        XCTAssertEqual(text(of: element("autopilot.guided.footer.text")), "Choose a header.")
        XCTAssertFalse(app.buttons.matching(identifier: "autopilot.guided.choose.look.use").firstMatch.exists, "No screenshot looks")
        attachScreenshot("Choose · a header only")

        ink.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch.click()
        XCTAssertTrue(waitUntil { use.isEnabled })
    }

    /// Header 21:9 only with Motion loop: the three concepts fit the
    /// sheet, Use These and Cancel Run… too, and a concept full size plays
    /// its loop.
    func testAHeaderLoopOnlyRunFitsTheSheet() {
        app.launch(debugScene: "st-choose-header-loop")
        let first = element("autopilot.choose.concept.A")
        XCTAssertTrue(first.waitForExistence(timeout: 20))
        attachScreenshot("Choose · header loops")

        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.exists, "No sheet")
        let bounds = sheet.frame.insetBy(dx: -1, dy: -1)
        for id in ["A", "B", "C"] {
            let card = element("autopilot.choose.concept.\(id)").frame
            XCTAssertTrue(bounds.contains(card), "Concept \(id) at \(card) is cut off by the sheet at \(bounds).")
        }
        for identifier in ["autopilot.guided.useChoices", "autopilot.cancelRun.later", "autopilot.guided.step.make"] {
            let frame = element(identifier).frame
            XCTAssertTrue(bounds.contains(frame), "\(identifier) at \(frame) is cut off by the sheet at \(bounds).")
        }

        first.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.zoom").firstMatch.click()
        XCTAssertTrue(app.buttons["artwork.loop.play"].waitForExistence(timeout: 20), "The concept's loop plays full size")
        XCTAssertTrue(text(of: element("studio.viewer.subtitle")).hasPrefix("20-second loop · plays muted on repeat"))
        attachScreenshot("Viewer · a concept's loop")
    }

    /// A loop full size plays, pauses, scrubs and skips with the player's
    /// controls, and Space plays it without closing the viewer.
    func testALoopFullSizeHasThePlayersControls() {
        app.launch(debugScene: "st-choose-header-loop")
        let first = element("autopilot.choose.concept.A")
        XCTAssertTrue(first.waitForExistence(timeout: 20))
        first.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.zoom").firstMatch.click()
        XCTAssertTrue(element("studio.viewer").waitForExistence(timeout: 10))
        let time = element("artwork.loop.time")
        XCTAssertTrue(time.waitForExistence(timeout: 20), "The loop plays")
        let start = text(of: time)
        XCTAssertTrue(waitUntil(timeout: 5) { self.text(of: time) != start }, "The time moves while it plays: \(start)")
        attachScreenshot("Viewer · loop playing")

        app.buttons["artwork.loop.play"].click()
        let paused = text(of: time)
        RunLoop.current.run(until: .now.addingTimeInterval(2.5))
        XCTAssertEqual(text(of: time), paused, "Paused, it stays put")

        // Scrub, then skip forward and back.
        element("artwork.loop.scrubber").coordinate(withNormalizedOffset: CGVector(dx: 0.27, dy: 0.5)).click()
        XCTAssertTrue(waitUntil { self.text(of: time).hasPrefix("0:05 / 0:20") }, text(of: time))
        app.buttons["artwork.loop.forward"].click()
        XCTAssertTrue(waitUntil { self.text(of: time).hasPrefix("0:10 / 0:20") }, text(of: time))
        app.buttons["artwork.loop.back"].click()
        app.buttons["artwork.loop.back"].click()
        XCTAssertTrue(waitUntil { self.text(of: time).hasPrefix("0:00 / 0:20") }, text(of: time))
        XCTAssertEqual(app.buttons["artwork.loop.play"].label, "Play the loop", "Still paused")
        app.typeKey(.space, modifierFlags: [])
        XCTAssertTrue(waitUntil { self.app.buttons["artwork.loop.play"].label == "Pause the loop" }, "Space plays it")
        XCTAssertTrue(element("studio.viewer").exists, "And doesn't close the viewer")
        attachScreenshot("Viewer · loop controls")
    }

    func testAskingForChangesToOneConcept() {
        app.launch(debugScene: "st-choose-free")
        let card = element("autopilot.choose.concept.B")
        XCTAssertTrue(card.waitForExistence(timeout: 20))
        card.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.ask").firstMatch.click()
        let note = element("autopilot.choose.concept.note")
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.click()
        note.typeText("Warmer sky")
        attachScreenshot("Choose · ask for changes to one concept")
        element("autopilot.choose.concept.send").click()
        XCTAssertTrue(element("autopilot.guided.making.steps").waitForExistence(timeout: 10), "Back to Making it for that concept")
    }

    func testAConceptOpensFullSize() {
        app.launch(debugScene: "st-lb-concept")
        let title = element("studio.viewer.title")
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        XCTAssertEqual(text(of: title), "Evening Hills · header · 21:9")
        XCTAssertTrue(text(of: element("studio.viewer.subtitle")).hasPrefix("Becomes a 20-second loop if you choose it · From the Layered Landscape template"))
        attachScreenshot("Viewer · a concept's header")
    }

    // MARK: - Review & push

    /// The header couldn't be made: Review & push's checks say so, and
    /// what went wrong.
    func testAHeaderThatWasntMadeNeedsALook() {
        app.launch(debugScene: "st-ready-header-failed")
        let made = element("autopilot.guided.review.check.made")
        XCTAssertTrue(made.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: made).hasPrefix("Needs a look: Couldn’t render the header page in English (U.S.)"), text(of: made))
        let title = element("autopilot.guided.review.artworkMissing.title")
        XCTAssertTrue(title.waitForExistence(timeout: 10), "The header part says it wasn't made")
        XCTAssertEqual(text(of: title), "Header artwork couldn’t be made")
        XCTAssertTrue(text(of: element("autopilot.guided.review.artworkMissing.detail")).hasSuffix("Approving pushes the rest without it."))
        XCTAssertFalse(element("autopilot.guided.review.artwork.header").exists, "No empty header thumbnail")
        let makeAgain = app.buttons["autopilot.guided.review.makeAgain"]
        XCTAssertTrue(makeAgain.exists)
        XCTAssertTrue(element("autopilot.guided.review.approve").isEnabled, "Approving pushes the rest without it")
        attachScreenshot("Review · header not made")

        makeAgain.click()
        XCTAssertTrue(element("autopilot.guided.review.artworkMissing").waitForNonExistence(timeout: 10), "Make Again takes the run back to making it")
        attachScreenshot("Review · Make Again")
    }

    func testWatchTheHeaderLoop() {
        app.launch(debugScene: "st-vid-loop")
        let loop = element("autopilot.loop")
        XCTAssertTrue(loop.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: element("autopilot.guided.title")), "Review everything")
        XCTAssertEqual(text(of: element("autopilot.loop.subtitle")), "Moonrise · 20 s · loops · muted")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.label.hasPrefix("Approve Header"), approve.label)
        let footer = text(of: element("autopilot.guided.footer.text"))
        XCTAssertTrue(footer.hasSuffix("Nothing is sent until you push."), footer)
        XCTAssertFalse(element("autopilot.guided.review.tabs").exists, "Only the header and search: no App Preview tab")
        attachScreenshot("Review · header loop v1")

        let quick = element("autopilot.loop.quickAsks").buttons["Slower movement"]
        quick.click()
        let note = element("autopilot.loop.note")
        XCTAssertTrue(waitUntil { self.text(of: note) == "Slower movement" }, text(of: note))
        element("autopilot.loop.ask").click()
        XCTAssertTrue(element("autopilot.loop.busy").waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("autopilot.loop.busy")).hasPrefix("Claude Design is revising the loop: “Slower movement”."))
        XCTAssertFalse(approve.isEnabled, "Approve waits for the new version")
    }

    /// The new version arrived: the bar, the languages and the time left,
    /// and why Approve is off.
    func testTheNewLoopBeingMadeSaysHowFarAndHowLong() {
        app.launch(debugScene: "st-vid-loop-making")
        let line = element("autopilot.loop.busy.line")
        XCTAssertTrue(line.waitForExistence(timeout: 20))
        XCTAssertTrue(text(of: line).contains(" languages · about "), text(of: line))
        XCTAssertFalse(element("autopilot.guided.review.approve").isEnabled)
        let note = text(of: element("autopilot.guided.review.approveNote"))
        XCTAssertTrue(note.hasPrefix("You can approve once the new loop is made · about "), note)
        attachScreenshot("Review · new loop being made")
    }

    func testTheLoopsVersionsSoFar() {
        app.launch(debugScene: "st-vid-loop-rev")
        let revisions = element("autopilot.loop.revisions")
        XCTAssertTrue(revisions.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: element("autopilot.loop.subtitle")), "Evening Hills · 20 s · loops · muted · Revised")
        let approve = element("autopilot.guided.review.approve")
        XCTAssertTrue(approve.isEnabled)
        attachScreenshot("Review · header loop v2")
        approve.click()
        XCTAssertTrue(waitUntil(timeout: 10) { !self.element("autopilot.loop").exists }, "Approved: the loop is kept and the run is ready to push")
    }

    // MARK: - Helpers

    /// The sheet opens a planned run at What to make: on to the Look.
    private func goToTheLook(showing identifier: String) {
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        next.click()
        XCTAssertTrue(element(identifier).waitForExistence(timeout: 5), "At Look")
    }

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
