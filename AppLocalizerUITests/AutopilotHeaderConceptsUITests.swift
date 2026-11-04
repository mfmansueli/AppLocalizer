//
//  AutopilotHeaderConceptsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Header concepts (board 33), on `StudioDebugHeaderStyle`'s scenes: the
/// plan's Header style (templates or Go freely) and Screenshot style,
/// Design's concept rows as they arrive, Choose's header and direction
/// apart with Use These, a concept full size, and Watch the header loop.
/// Each test attaches the window's screenshot.
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

    // MARK: - Plan

    func testTheHeaderStyleStartsFromThreeTemplates() {
        app.launch(debugScene: "st-plan-tpl")
        let box = element("autopilot.plan.headerStyleBox")
        XCTAssertTrue(box.waitForExistence(timeout: 20))
        reveal(box)
        XCTAssertTrue(element("autopilot.plan.headerStyle.templates").isSelected)
        let note = element("autopilot.plan.headerStyle.note")
        XCTAssertTrue(text(of: note).hasSuffix("3 of 3 picked."), text(of: note))
        XCTAssertEqual(element("autopilot.plan.headerTemplate.night").label, "Remove Day to Night")
        XCTAssertEqual(element("autopilot.plan.headerTemplate.hero").label, "Add Hero Object")
        attachScreenshot("Plan · header style from templates")

        tap("autopilot.plan.headerTemplate.hero")
        XCTAssertTrue(waitUntil { self.element("autopilot.plan.headerTemplate.hero").label == "Remove Hero Object" })
        XCTAssertEqual(element("autopilot.plan.headerTemplate.window").label, "Add Window View", "A fourth replaces the last")
        tap("autopilot.plan.headerTemplate.land")
        XCTAssertTrue(waitUntil { self.text(of: note).hasSuffix("2 of 3 picked.") }, text(of: note))
    }

    func testGoingFreelyShowsWhatTheDesignerGets() {
        app.launch(debugScene: "st-plan-free")
        let free = element("autopilot.plan.headerStyle.freeText")
        XCTAssertTrue(free.waitForExistence(timeout: 20))
        reveal(free)
        XCTAssertTrue(text(of: free).hasPrefix("Claude Design studies Lumen Journal and proposes 3 concepts of its own"), text(of: free))
        let scan = element("autopilot.plan.headerStyle.scan")
        XCTAssertTrue(scan.exists)
        XCTAssertFalse(element("autopilot.plan.headerTemplate.night").exists, "No templates to pick")
        attachScreenshot("Plan · go freely")

        tap("autopilot.plan.headerStyle.templates")
        XCTAssertTrue(element("autopilot.plan.headerTemplate.night").waitForExistence(timeout: 5))
    }

    func testTheScreenshotStyleTakesGalleryTemplates() {
        app.launch(debugScene: "st-plan-shotstyle")
        let note = element("autopilot.plan.shotStyle.note")
        XCTAssertTrue(note.waitForExistence(timeout: 20))
        reveal(note)
        XCTAssertTrue(element("autopilot.plan.shotStyle.templates").isSelected)
        XCTAssertTrue(text(of: note).hasSuffix("2 of 3 picked."), text(of: note))
        attachScreenshot("Plan · screenshot style from templates")

        let pills = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'autopilot.plan.shotTemplate.'"))
        XCTAssertEqual(pills.count, 12, "The twelve gallery templates")
        pills.element(boundBy: 0).click()
        XCTAssertTrue(waitUntil { self.text(of: note).hasSuffix("3 of 3 picked.") }, text(of: note))
        tap("autopilot.plan.shotStyle.free")
        XCTAssertTrue(waitUntil { self.text(of: note).contains("designs 3 directions of its own") }, text(of: note))
        XCTAssertEqual(pills.count, 0)
    }

    // MARK: - Design

    func testConceptsFillInAsTheyArrive() {
        app.launch(debugScene: "st-des-tpl")
        let concepts = element("autopilot.design.concepts")
        XCTAssertTrue(concepts.waitForExistence(timeout: 20))
        let next = element("autopilot.design.next")
        XCTAssertTrue(text(of: next).hasPrefix("Next, you choose: 1 of 3 headers."), text(of: next))
        XCTAssertTrue(text(of: element("autopilot.design.concept.0")).contains("Moonrise"))
        XCTAssertTrue(text(of: element("autopilot.design.concept.1")).contains("Evening Hills"), "An idea shows before its pages")
        XCTAssertTrue(text(of: element("autopilot.design.concept.2")).contains("Concept 3 · from the Window View template"))
        XCTAssertFalse(element("autopilot.design.direction.0").exists, "Only the header: no directions")
        attachScreenshot("Design · concepts from templates")
    }

    // MARK: - Choose

    func testChooseTakesADirectionAndAHeader() {
        app.launch(debugScene: "st-choose-tpl")
        let title = element("autopilot.choose.title")
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: title), "Choose a direction and a header")
        XCTAssertTrue(text(of: element("autopilot.choose.conceptsFrom")).hasPrefix("From your templates · header and search share one look"))
        XCTAssertTrue(element("autopilot.choose.concept.A").exists)
        let use = element("autopilot.choose.useChoices")
        XCTAssertEqual(use.label, "Use These")
        XCTAssertTrue(use.isEnabled, "A direction and a header are chosen")
        XCTAssertTrue(text(of: element("autopilot.footer.text")).hasPrefix("Your direction becomes template v"), text(of: element("autopilot.footer.text")))
        attachScreenshot("Choose · direction and header")

        let evening = element("autopilot.choose.concept.B")
        evening.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch.click()
        XCTAssertTrue(waitUntil { evening.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch.label == "Chosen" })
        let moonrise = element("autopilot.choose.concept.A").descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch
        XCTAssertEqual(moonrise.label, "Choose", "One header at a time")
    }

    func testAHeaderOnlyRunWaitsForTheHeader() {
        app.launch(debugScene: "st-choose-free")
        let title = element("autopilot.choose.title")
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: title), "Choose a header")
        let use = element("autopilot.choose.useChoices")
        XCTAssertEqual(use.label, "Use This Header")
        XCTAssertFalse(use.isEnabled, "No header chosen yet")
        XCTAssertEqual(text(of: element("autopilot.footer.text")), "Choose a header.")
        XCTAssertFalse(element("autopilot.direction.use").exists, "No directions")
        attachScreenshot("Choose · a header only")

        let ink = element("autopilot.choose.concept.A")
        ink.descendants(matching: .any).matching(identifier: "autopilot.choose.concept.use").firstMatch.click()
        XCTAssertTrue(waitUntil { use.isEnabled })
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
        XCTAssertTrue(element("autopilot.design").waitForExistence(timeout: 10), "Back to Design for that concept")
    }

    func testAConceptOpensFullSize() {
        app.launch(debugScene: "st-lb-concept")
        let title = element("studio.viewer.title")
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        XCTAssertEqual(text(of: title), "Evening Hills · header · 21:9")
        XCTAssertTrue(text(of: element("studio.viewer.subtitle")).hasPrefix("Becomes a 20-second loop if you choose it · From the Layered Landscape template"))
        attachScreenshot("Viewer · a concept's header")
    }

    // MARK: - Watch the header loop

    func testWatchTheHeaderLoop() {
        app.launch(debugScene: "st-vid-loop")
        let loop = element("autopilot.loop")
        XCTAssertTrue(loop.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: element("autopilot.watch.title")), "Watch the header loop")
        XCTAssertEqual(text(of: element("autopilot.loop.subtitle")), "Moonrise · 20 s · loops · muted · v1")
        let approve = element("autopilot.watch.approve")
        XCTAssertEqual(approve.label, "Approve Header Loop")
        XCTAssertEqual(text(of: element("autopilot.footer.text")), "Approving keeps this loop for the header and search in every language.")
        XCTAssertFalse(element("autopilot.watch.subtitle").exists, "No App Preview")
        attachScreenshot("Watch · header loop v1")

        let quick = element("autopilot.loop.quickAsks").buttons["Slower movement"]
        quick.click()
        let note = element("autopilot.loop.note")
        XCTAssertTrue(waitUntil { self.text(of: note) == "Slower movement" }, text(of: note))
        element("autopilot.loop.ask").click()
        XCTAssertTrue(element("autopilot.loop.busy").waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: element("autopilot.loop.busy")).hasPrefix("Claude Design is revising the loop: “Slower movement”."))
        XCTAssertFalse(approve.isEnabled, "Approve waits for the new version")
    }

    func testTheLoopsVersionsSoFar() {
        app.launch(debugScene: "st-vid-loop-rev")
        let revisions = element("autopilot.loop.revisions")
        XCTAssertTrue(revisions.waitForExistence(timeout: 20))
        XCTAssertEqual(text(of: element("autopilot.loop.subtitle")), "Evening Hills · 20 s · loops · muted · v2")
        XCTAssertTrue(element("autopilot.watch.approve").isEnabled)
        attachScreenshot("Watch · header loop v2")
        element("autopilot.watch.approve").click()
        XCTAssertTrue(waitUntil(timeout: 10) { !self.element("autopilot.loop").exists }, "On to Review & Push")
    }

    // MARK: - Helpers

    /// Scrolls the plan until `target` is inside what it shows.
    private func reveal(_ target: XCUIElement) {
        let plan = element("autopilot.plan")
        guard plan.exists else { return }
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
