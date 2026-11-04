//
//  AutopilotRunChoiceUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// The Autopilot plan's "What this run makes" (presets, rows, languages,
/// captures) and its two ways to add a screen ("+ Add a Screen…" and
/// Suggest Screens), driven through the DEBUG scenes in
/// `StudioDebugRunChoice` and `StudioDebugAddScreens`. Each test attaches
/// the sheet's screenshot to check the layout.
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

    func testAPresetSetsTheRowsAndNothingSelectedKeepsStartOff() {
        launch(scene: "st-plan")
        let summary = element("autopilot.plan.runSummary")
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: summary).hasPrefix("This run makes 180 screenshots for iPhone"), text(of: summary))
        XCTAssertTrue(element("autopilot.plan.preset.screenshots").isSelected)
        attachScreenshot("Plan · Screenshots")

        tap("autopilot.plan.preset.headerAndSearch")
        XCTAssertTrue(waitUntil {
            self.text(of: summary) == "This run makes header and search artwork in 12 languages. Everything else on the App Store stays as it is."
        }, text(of: summary))
        XCTAssertEqual(element("autopilot.plan.screenshots").value as? Int, 0)
        XCTAssertFalse(element("autopilot.plan.iPad").isEnabled, "No screenshots, no devices to pick")
        XCTAssertTrue(text(of: element("autopilot.plan.captureNote")).hasPrefix("Claude Code runs this build and captures again"))
        attachScreenshot("Plan · Header and search")

        tap("autopilot.plan.artwork")
        XCTAssertTrue(waitUntil { self.text(of: summary) == "Nothing selected. Turn on at least one row." }, text(of: summary))
        XCTAssertTrue(element("autopilot.plan.preset.custom").exists)
        XCTAssertFalse(app.buttons["autopilot.start"].isEnabled)
        attachScreenshot("Plan · Nothing selected")

        tap("autopilot.plan.preset.screenshots")
        XCTAssertTrue(waitUntil { self.app.buttons["autopilot.start"].isEnabled })
    }

    func testOnlyThePrimaryLanguageOrTheOnesChosen() {
        launch(scene: "st-plan")
        let summary = element("autopilot.plan.runSummary")
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        tap("autopilot.plan.languages.primary")
        XCTAssertTrue(waitUntil { self.text(of: summary).contains("in English (U.S.).") }, text(of: summary))

        tap("autopilot.plan.languages.chosen")
        let german = element("autopilot.plan.language.de-DE")
        XCTAssertTrue(german.waitForExistence(timeout: 5))
        reveal(german)
        german.click()
        XCTAssertTrue(waitUntil { self.text(of: summary).contains("in 2 languages") }, text(of: summary))
        attachScreenshot("Plan · Chosen languages")
    }

    func testReusingTheLastCapturesSkipsCaptureAndPick() {
        launch(scene: "st-plan-reuse")
        let note = element("autopilot.plan.captureNote")
        XCTAssertTrue(note.waitForExistence(timeout: 15))
        XCTAssertTrue(element("autopilot.plan.captureSource.reuse").isSelected)
        XCTAssertTrue(text(of: note).contains("Faster, but shows the app as it was on"), text(of: note))
        attachScreenshot("Plan · Reuse captures")
    }

    func testTheReadyStageOfAnArtworkRunSaysTheScreenshotsStay() {
        launch(scene: "st-ready-art")
        let ready = element("autopilot.ready")
        XCTAssertTrue(ready.waitForExistence(timeout: 15))
        attachScreenshot("Ready · header and search only")
    }

    // MARK: - Add or suggest screens

    func testAScreenAddedByNameIsTaggedAndLeftToClaudeCode() {
        launch(scene: "st-plan")
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
        XCTAssertTrue(confirm.isHittable, "The form scrolls into view")
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
        let title = element("autopilot.plan.suggestions.title")
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        reveal(title)
        XCTAssertEqual(text(of: title), "For “one that shows the streak”")
        attachScreenshot("Plan · Suggestions for an ask")
    }

    func testSuggestingCanBeCancelledWhileClaudeCodeReads() {
        launch(scene: "st-plan-suggest-busy")
        let busy = element("autopilot.plan.suggestions.busy")
        XCTAssertTrue(busy.waitForExistence(timeout: 15))
        reveal(busy)
        let reading = text(of: element("autopilot.plan.suggestions.busyText"))
        XCTAssertTrue(reading.hasPrefix("Claude Code is reading LumenUITests, the "), reading)
        XCTAssertFalse(element("autopilot.plan.suggestScreens").isEnabled)
        attachScreenshot("Plan · Suggesting")
        element("autopilot.plan.suggestions.cancel").click()
        XCTAssertTrue(waitUntil { !busy.exists })
        XCTAssertTrue(element("autopilot.plan.suggestScreens").isEnabled)
    }

    func testTheAddedScreensSceneShowsBothTags() {
        launch(scene: "st-plan-added")
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
        let busy = element("autopilot.plan.suggestions.busy")
        XCTAssertTrue(busy.waitForExistence(timeout: 15))
        reveal(busy)
        let reading = text(of: element("autopilot.plan.suggestions.busyText"))
        XCTAssertTrue(reading.hasPrefix("Claude Code is reading the watch app"), reading)
        XCTAssertFalse(element("autopilot.plan.suggestScreens.watch").isEnabled)
        XCTAssertFalse(element("autopilot.plan.suggestScreens").isEnabled)
        attachScreenshot("Plan · Suggesting watch screens")
        element("autopilot.plan.suggestions.cancel").click()
        XCTAssertTrue(waitUntil { !busy.exists })
        XCTAssertTrue(element("autopilot.plan.suggestScreens.watch").isEnabled)
    }

    // MARK: - Helpers

    /// Scrolls `identifier` into view and clicks it.
    private func tap(_ identifier: String) {
        let target = element(identifier)
        reveal(target)
        target.click()
    }

    /// Scrolls the plan until `target` is inside what it shows
    /// (`isHittable` is true for rows the scroll view clips).
    private func reveal(_ target: XCUIElement) {
        let plan = element("autopilot.plan")
        var tries = 0
        while !(target.frame.minY >= plan.frame.minY && target.frame.maxY <= plan.frame.maxY), tries < 12 {
            plan.scroll(byDeltaX: 0, deltaY: target.frame.minY < plan.frame.minY ? 200 : -200)
            tries += 1
        }
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
