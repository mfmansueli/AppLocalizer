//
//  AutopilotRunChoiceUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// What the run makes (languages at What to make, reused captures in the
/// plan, Review & push of a header-only run) and the plan's two ways to
/// add a screen ("+ Add a Screen…" and Suggest Screens, under Show
/// screens), driven through the DEBUG scenes in `StudioDebugRunChoice` and
/// `StudioDebugAddScreens`. Each test attaches the sheet's screenshot to
/// check the layout.
@MainActor
final class AutopilotRunChoiceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - What this run makes

    func testOnlyThePrimaryLanguageOrTheOnesChosen() {
        launch(scene: "st-plan")
        let primary = element("autopilot.guided.make.languages.primary")
        XCTAssertTrue(primary.waitForExistence(timeout: 15))
        let footer = element("autopilot.guided.footer.text")
        click(primary)
        XCTAssertTrue(waitUntil { self.text(of: footer).contains("in English (U.S.).") }, text(of: footer))

        tap("autopilot.guided.make.languages.chosen")
        let german = element("autopilot.plan.language.de-DE")
        XCTAssertTrue(german.waitForExistence(timeout: 5))
        click(german)
        XCTAssertTrue(waitUntil { self.text(of: footer).contains("in 2 languages") }, text(of: footer))
        attachScreenshot("What to make · Chosen languages")
    }

    /// Reusing the last captures: nothing to capture, and turned off, the
    /// plan captures again.
    func testReusingTheLastCapturesSkipsCapture() {
        launch(scene: "st-plan-reuse")
        goToThePlan()
        showScreens()
        let reuse = element("autopilot.guided.plan.reuse")
        XCTAssertTrue(reuse.waitForExistence(timeout: 5))
        XCTAssertTrue(reuse.label.hasPrefix("Reuse "), reuse.label)
        XCTAssertEqual(reuse.value as? Int, 1, "Reuse is on")
        // The last run made iPhone and iPad; this plan has iPhone Duo too.
        let title = element("autopilot.guided.plan.row.capture.title")
        XCTAssertTrue(text(of: title).hasPrefix("Reuses "), text(of: title))
        XCTAssertTrue(text(of: title).contains(" more in Simulator"), text(of: title))
        let detail = text(of: element("autopilot.guided.plan.row.capture.detail"))
        XCTAssertTrue(detail.hasPrefix("The captures and picks of the last run"), detail)
        attachScreenshot("Plan · Reuse captures")

        click(reuse)
        XCTAssertTrue(waitUntil { self.text(of: title).hasPrefix("Captures") }, text(of: title))
    }

    /// Review & push in a run that makes only the header and search: one
    /// part and no tabs, and the sheet says the run made no screenshots.
    func testReviewingAnArtworkRunShowsNoScreenshots() {
        launch(scene: "st-ready-art")
        let artwork = element("autopilot.guided.review.artwork")
        XCTAssertTrue(artwork.waitForExistence(timeout: 15))
        XCTAssertFalse(element("autopilot.guided.review.tabs").exists, "One part: no tabs")
        let subtitle = text(of: element("autopilot.guided.sheetSubtitle"))
        XCTAssertTrue(subtitle.contains("header and search"), subtitle)
        XCTAssertFalse(subtitle.contains("screenshots"), subtitle)
        attachScreenshot("Review · header and search only")
    }

    // MARK: - Add or suggest screens

    func testAScreenAddedByNameIsTaggedAndLeftToClaudeCode() {
        launch(scene: "st-plan")
        goToThePlan()
        showScreens()
        let add = element("autopilot.plan.addScreen")
        XCTAssertTrue(add.waitForExistence(timeout: 15))
        reveal(add)
        add.click()
        let name = element("autopilot.plan.form.name")
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertFalse(element("autopilot.plan.form.add").isEnabled, "A name first")
        XCTAssertEqual(element("autopilot.plan.form.worksOutSteps").value as? Int, 1)
        XCTAssertFalse(element("autopilot.plan.form.steps").isEnabled, "Claude Code works out the steps")
        name.click()
        name.typeText("Insights")
        let confirm = element("autopilot.plan.form.add")
        reveal(confirm)
        attachScreenshot("Plan · Add a Screen form")
        confirm.click()

        let tag = element("autopilot.plan.origin.5")
        XCTAssertTrue(tag.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: tag), "Added by you")
        XCTAssertFalse(element("autopilot.plan.form").exists)
        XCTAssertTrue(text(of: element("autopilot.plan.addScreensNote")).hasPrefix("New screens go after screen 6"))
        reveal(tag)
        attachScreenshot("Plan · Added by you")
    }

    func testSuggestionsAreAddedOrDismissedOneByOne() {
        launch(scene: "st-plan-suggest")
        goToThePlan()
        showScreens()
        let insights = element("autopilot.plan.suggestion.sg-insights.add")
        XCTAssertTrue(insights.waitForExistence(timeout: 15))
        reveal(insights)
        XCTAssertEqual(text(of: element("autopilot.plan.suggestions.title")), "Screens Lumen Journal’s set is missing")
        attachScreenshot("Plan · Suggestions")

        insights.click()
        XCTAssertTrue(element("autopilot.plan.suggestion.sg-insights.added").waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: element("autopilot.plan.origin.5")), "Suggested by Claude Code")

        element("autopilot.plan.suggestion.sg-dark.dismiss").click()
        XCTAssertTrue(waitUntil { !self.element("autopilot.plan.suggestion.sg-dark").exists })
        attachScreenshot("Plan · One added, one dismissed")

        element("autopilot.plan.suggestions.done").click()
        XCTAssertTrue(waitUntil { !self.element("autopilot.plan.suggestions").exists })
        XCTAssertTrue(element("autopilot.plan.origin.5").exists, "The added screen stays")
    }

    func testAskingForAScreenShowsWhatWasAskedFor() {
        launch(scene: "st-plan-suggest-ask")
        goToThePlan()
        showScreens()
        let title = element("autopilot.plan.suggestions.title")
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        reveal(title)
        XCTAssertEqual(text(of: title), "For “one that shows the streak”")
        attachScreenshot("Plan · Suggestions for an ask")
    }

    func testSuggestingCanBeCancelledWhileClaudeCodeReads() {
        launch(scene: "st-plan-suggest-busy")
        goToThePlan()
        showScreens()
        let busy = element("autopilot.plan.suggestions.busyText")
        XCTAssertTrue(busy.waitForExistence(timeout: 15))
        reveal(busy)
        let reading = text(of: busy)
        XCTAssertTrue(reading.hasPrefix("Claude Code is reading LumenUITests, the "), reading)
        XCTAssertFalse(element("autopilot.plan.suggestScreens").isEnabled)
        attachScreenshot("Plan · Suggesting")
        element("autopilot.plan.suggestions.cancel").click()
        XCTAssertTrue(waitUntil { !busy.exists })
        XCTAssertTrue(element("autopilot.plan.suggestScreens").isEnabled)
    }

    func testTheAddedScreensSceneShowsBothTags() {
        launch(scene: "st-plan-added")
        goToThePlan()
        showScreens()
        let suggested = element("autopilot.plan.origin.5")
        XCTAssertTrue(suggested.waitForExistence(timeout: 15))
        reveal(element("autopilot.plan.origin.6"))
        XCTAssertEqual(text(of: suggested), "Suggested by Claude Code")
        XCTAssertEqual(text(of: element("autopilot.plan.origin.6")), "Added by you")
        attachScreenshot("Plan · Added screens")
    }

    // MARK: - Apple Watch screens

    /// "+ Add a Screen…" under Apple Watch's screens: no caption, and it
    /// goes after the watch's, not the set's.
    func testAWatchScreenIsAddedAfterTheWatchsOwn() {
        launch(scene: "st-plan-all")
        goToThePlan()
        showScreens()
        let add = element("autopilot.plan.addScreen.watch")
        XCTAssertTrue(add.waitForExistence(timeout: 15))
        reveal(add)
        add.click()
        let name = element("autopilot.plan.form.name")
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertFalse(element("autopilot.plan.form.caption").exists, "No caption on the watch")
        XCTAssertTrue(text(of: element("autopilot.plan.form.note")).hasPrefix("Captured on Apple Watch"))
        name.click()
        name.typeText("Mood history")
        attachScreenshot("Plan · Add a watch screen")
        element("autopilot.plan.form.add").click()

        let tag = element("autopilot.plan.origin.watch.4")
        XCTAssertTrue(tag.waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: tag), "Added by you")
        XCTAssertFalse(element("autopilot.plan.origin.5").exists, "Not in the set")
        XCTAssertTrue(text(of: element("autopilot.plan.addScreensNote.watch")).hasPrefix("New screens go after screen 5 on Apple Watch"))
        XCTAssertTrue(text(of: element("autopilot.plan.addScreensNote")).hasPrefix("New screens go after screen 5 on iPhone and iPad"))
    }

    func testWatchSuggestionsAreAddedToTheWatch() {
        launch(scene: "st-plan-watch-suggest")
        goToThePlan()
        showScreens()
        let add = element("autopilot.plan.suggestion.sg-watch-stack.add")
        XCTAssertTrue(add.waitForExistence(timeout: 15))
        reveal(add)
        XCTAssertEqual(text(of: element("autopilot.plan.suggestions.title")), "Apple Watch screens Lumen Journal is missing")
        attachScreenshot("Plan · Watch suggestions")
        add.click()
        XCTAssertTrue(element("autopilot.plan.suggestion.sg-watch-stack.added").waitForExistence(timeout: 5))
        XCTAssertEqual(text(of: element("autopilot.plan.origin.watch.4")), "Suggested by Claude Code")
        XCTAssertFalse(element("autopilot.plan.origin.5").exists, "Not in the set")
    }

    /// One request at a time: while the watch's is read, neither device
    /// can ask.
    func testSuggestingForTheWatchWaitsUnderTheWatch() {
        launch(scene: "st-plan-watch-busy")
        goToThePlan()
        showScreens()
        let busy = element("autopilot.plan.suggestions.busyText")
        XCTAssertTrue(busy.waitForExistence(timeout: 15))
        reveal(busy)
        let reading = text(of: busy)
        XCTAssertTrue(reading.hasPrefix("Claude Code is reading the watch app"), reading)
        XCTAssertFalse(element("autopilot.plan.suggestScreens.watch").isEnabled)
        XCTAssertFalse(element("autopilot.plan.suggestScreens").isEnabled)
        attachScreenshot("Plan · Suggesting watch screens")
        element("autopilot.plan.suggestions.cancel").click()
        XCTAssertTrue(waitUntil { !busy.exists })
        XCTAssertTrue(element("autopilot.plan.suggestScreens.watch").isEnabled)
    }

    // MARK: - Helpers

    /// The sheet opens a planned run at What to make: on to the plan.
    private func goToThePlan() {
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        next.click()
        XCTAssertTrue(element("autopilot.guided.back").waitForExistence(timeout: 5), "At Look")
        element("autopilot.guided.next").click()
        XCTAssertTrue(element("autopilot.guided.plan.timeline").waitForExistence(timeout: 5), "At the plan")
    }

    /// The plan's screens are folded under the capture line: shows them.
    private func showScreens() {
        let toggle = element("autopilot.guided.plan.screens.toggle")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        if (toggle.value as? String) != "Shown" { click(toggle) }
        XCTAssertTrue(element("autopilot.plan.addScreen").waitForExistence(timeout: 5), "The screens are shown")
    }

    /// Scrolls the step until `target` is above the footer: the content
    /// scrolls under it, so a click on what's below would hit the footer
    /// (`isHittable` is true for rows the scroll view clips).
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

    /// Scrolls `identifier` into view and clicks it.
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

    private func launch(scene: String) {
        app.launch(debugScene: scene)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
