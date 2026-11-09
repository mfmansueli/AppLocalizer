//
//  ScreenshotStudioUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Screenshots → Preview, driven through the DEBUG scenes in
/// `StudioDebugScenes` (Lumen Journal with sample runs held at each
/// stage; nothing moves on by itself and nothing leaves the Mac): the App
/// Store preview, the Autopilot strip, the guided Autopilot sheet (What to
/// make, the plan, Making it, Choose) and Connect a Design Project.
@MainActor
final class ScreenshotStudioUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - The page

    func testScreenshotsOpensOnThePreviewWithAutopilot() {
        launch(scene: "st-home")
        XCTAssertTrue(element("workspace.screenshots").waitForExistence(timeout: 15))
        XCTAssertTrue(element("studio.root").waitForExistence(timeout: 15))
        XCTAssertTrue(element("studio.store").exists)
        XCTAssertTrue(element("studio.shot.0").waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["studio.autopilot.run"].exists)
        XCTAssertTrue(element("studio.setCard").exists)
        XCTAssertTrue(app.buttons["studio.set.live"].exists)
    }

    func testScreenshotsIsTheFourthSection() {
        launch(scene: "st-home")
        XCTAssertTrue(element("studio.root").waitForExistence(timeout: 15))
        app.typeKey("5", modifierFlags: .command)
        XCTAssertTrue(element("workspace.appInformation").waitForExistence(timeout: 10))
        app.typeKey("4", modifierFlags: .command)
        XCTAssertTrue(element("workspace.screenshots").waitForExistence(timeout: 10))
    }

    func testArabicShowsTheStoreInArabic() {
        launch(scene: "st-live-ar")
        XCTAssertTrue(element("studio.store").waitForExistence(timeout: 15))
        let get = NSPredicate(format: "label == %@ OR value == %@", "احصل", "احصل")
        XCTAssertTrue(app.descendants(matching: .any).matching(get).firstMatch.waitForExistence(timeout: 5))
    }

    func testWithoutAnAssistantCapturesCanBeImported() {
        launch(scene: "st-noasst")
        let pill = element("studio.autopilot.pill")
        XCTAssertTrue(pill.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: pill), "Needs an assistant")
        XCTAssertTrue(app.buttons["studio.autopilot.import"].exists)
        XCTAssertTrue(app.buttons["studio.autopilot.setUp"].exists)
        XCTAssertFalse(app.buttons["studio.autopilot.run"].exists)
    }

    func testAProblemShowsOnTheStripAndOpensTheSheet() {
        launch(scene: "st-cap-page")
        let pill = element("studio.autopilot.pill")
        XCTAssertTrue(pill.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: pill), "1 problem")
        app.buttons["studio.autopilot.open"].click()
        XCTAssertTrue(element("autopilot.guided.sheet").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.problem").waitForExistence(timeout: 5), "Making it shows the problem")
    }

    func testTheReadySetSwitchesBetweenNewAndLive() {
        launch(scene: "st-ready")
        let title = element("studio.setCard.title")
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: title), "New set")
        let review = app.buttons["studio.autopilot.open"]
        XCTAssertTrue(review.exists)
        XCTAssertEqual(review.title.isEmpty ? review.label : review.title, "Review…", "Guided: the review comes before the push")
        app.buttons["studio.set.live"].click()
        XCTAssertTrue(waitForText(of: title, toBe: "Live set"))
        app.buttons["studio.set.new"].click()
        XCTAssertTrue(waitForText(of: title, toBe: "New set"))
    }

    // MARK: - Autopilot sheet

    func testStartSetsUpARunAndCancelKeepsNothing() {
        launch(scene: "st-home")
        let run = app.buttons["studio.autopilot.run"]
        XCTAssertTrue(run.waitForExistence(timeout: 15))
        run.click()
        XCTAssertTrue(element("autopilot.guided.sheet").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.guided.make.screenshots").waitForExistence(timeout: 5))
        app.buttons["autopilot.guided.cancel"].click()
        XCTAssertTrue(element("autopilot.guided.sheet").waitForNonExistence(timeout: 5))
        XCTAssertTrue(run.waitForExistence(timeout: 5))
        XCTAssertEqual(run.label, "Start…", "The plan is gone: nothing to continue")
    }

    func testStartCopiesThePromptAndCancelRunGoesBackToThePlan() {
        launch(scene: "st-plan")
        let start = goToThePlan()
        start.click()
        XCTAssertTrue(element("autopilot.wait").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.wait.copied").exists)
        XCTAssertFalse(text(of: element("autopilot.wait.prompt")).isEmpty)
        app.buttons["autopilot.guided.cancelRun"].click()
        XCTAssertTrue(element("autopilot.guided.plan.timeline").waitForExistence(timeout: 5), "Back at the plan")
    }

    func testCancelAsksOncePastTheFirstStep() {
        launch(scene: "st-plan")
        _ = goToThePlan()
        app.buttons["autopilot.guided.cancel"].click()
        let keep = app.buttons["autopilot.guided.cancel.keep"]
        XCTAssertTrue(keep.waitForExistence(timeout: 5), "Asks first")
        keep.click()
        XCTAssertTrue(element("autopilot.guided.sheet").exists, "Still planning")

        app.buttons["autopilot.guided.cancel"].click()
        let confirm = app.buttons["autopilot.guided.cancel.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.click()
        XCTAssertTrue(element("autopilot.guided.sheet").waitForNonExistence(timeout: 5))
    }

    func testThePersonCanKeepTheirScreens() {
        launch(scene: "st-plan")
        let start = goToThePlan()
        element("autopilot.guided.plan.screens.toggle").click()
        let picks = element("autopilot.guided.plan.choosesScreens")
        XCTAssertTrue(picks.waitForExistence(timeout: 5))
        XCTAssertEqual(picks.value as? Int, 1, "Claude Code picks the screens unless the person keeps theirs")
        picks.click()
        start.click()
        let prompt = element("autopilot.wait.prompt")
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: prompt).contains("capture the 5 screens"))
        XCTAssertFalse(text(of: prompt).contains("decide which screens"))
    }

    /// iPhone Duo is Apple's rule from April 2027, so a plan has it; the
    /// iPad can be left out on What to make.
    func testThePlanHasIPhoneDuoAndCanDropTheIPad() {
        launch(scene: "st-plan")
        let iPad = element("autopilot.guided.make.device.iPad")
        XCTAssertTrue(iPad.waitForExistence(timeout: 15))
        let duo = element("autopilot.guided.make.device.iphone_duo")
        XCTAssertTrue(duo.isSelected, "iPhone Duo is in every plan")
        XCTAssertTrue(iPad.isSelected)
        let footer = element("autopilot.guided.footer.text")
        let before = text(of: footer)
        iPad.click()
        XCTAssertTrue(waitUntil { !iPad.isSelected })
        XCTAssertTrue(duo.isSelected)
        XCTAssertTrue(waitUntil { self.text(of: footer) != before }, "Fewer screenshots without the iPad: \(text(of: footer))")
    }

    func testRetryingWithTheFixClearsTheProblem() {
        launch(scene: "st-fail")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        XCTAssertTrue(element("autopilot.guided.making.details").exists, "The log is under Show details")
        let retry = app.buttons["autopilot.problem.retry"]
        reveal(retry)
        retry.click()
        XCTAssertTrue(problem.waitForNonExistence(timeout: 5))
    }

    /// A refused command shows what to change in the project, and retrying
    /// doesn't offer it as a fix to run.
    func testARefusedCommandSaysWhatToChange() {
        launch(scene: "st-refused")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        let allowed = "a command wasn’t allowed"
        let headline = problem.staticTexts.matching(NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", allowed, allowed))
        XCTAssertTrue(headline.firstMatch.exists)
        XCTAssertTrue(text(of: element("autopilot.problem.refused")).hasPrefix("TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild"))
        XCTAssertTrue(element("autopilot.problem.refusedNote").exists)
        let retry = app.buttons["autopilot.problem.retry"]
        XCTAssertEqual(retry.title.isEmpty ? retry.label : retry.title, "Retry")
        // The card's buttons sit under the footer until the step scrolls.
        reveal(retry)
        retry.click()
        XCTAssertTrue(problem.waitForNonExistence(timeout: 5))
    }

    /// One change to the project stopped Week in two languages on iPhone
    /// and iPad: one card, saying what to change, answered for all three.
    func testOneCauseInSeveralLanguagesIsOneCard() {
        launch(scene: "st-group")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "autopilot.problem").count, 1)
        let place = "on iPhone and iPad: couldn’t reach the screen"
        XCTAssertTrue(problem.staticTexts.matching(NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", place, place)).firstMatch.exists)
        XCTAssertTrue(text(of: element("autopilot.problem.fix")).hasPrefix("In LumenUITests/ScreenshotTests.swift:64"))
        XCTAssertTrue(element("autopilot.problem.note").exists)
        XCTAssertFalse(app.buttons["autopilot.problem.upload"].exists, "Uploading by hand is one screen at a time")
        let retry = app.buttons["autopilot.problem.retry"]
        XCTAssertEqual(retry.title.isEmpty ? retry.label : retry.title, "Retry")
        app.buttons["autopilot.problem.usePrimary"].click()
        XCTAssertTrue(problem.waitForNonExistence(timeout: 5))
    }

    /// AppLocalizer read every capture's text: the Japanese Week screen came
    /// back in English and a German label is cut off.
    func testThePickStepListsTheCapturesToCheck() {
        launch(scene: "st-pick")
        let card = element("autopilot.pick.toCheck")
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        let japanese = element("autopilot.pick.toCheck.ja.week")
        XCTAssertTrue(japanese.exists)
        XCTAssertTrue(text(of: japanese).contains("English, not Japanese"), text(of: japanese))
        XCTAssertTrue(element("autopilot.pick.toCheck.de-DE.search").exists)
    }

    /// The plan's Simulator options: sample data in each language while the
    /// app is captured in each; one switch, plain sample data, once the
    /// English captures are reused.
    func testThePlanUsesSampleDataInEachLanguage() {
        launch(scene: "st-plan")
        openThePlan()
        let simulator = element("autopilot.guided.plan.simulator")
        reveal(simulator)
        simulator.click()
        let sampleData = element("autopilot.plan.sampleDataLanguage")
        XCTAssertTrue(sampleData.waitForExistence(timeout: 5))
        reveal(sampleData)
        XCTAssertEqual(sampleData.value as? Int, 1)
        XCTAssertTrue(sampleData.isEnabled)
        let name = { "\(sampleData.title) \(sampleData.label)" }
        XCTAssertTrue(name().contains("Sample data in each language"), name())
        reveal(element("autopilot.plan.eachLanguage"))
        element("autopilot.plan.eachLanguage").click()
        XCTAssertTrue(waitUntil { !name().contains("in each language") }, "English captures are reused: one language's data")
        XCTAssertEqual(sampleData.value as? Int, 1, "Sample data stays on")
        XCTAssertTrue(sampleData.isEnabled)
    }

    func testPickingAnotherCaptureThenUsingThePicksStartsDesign() {
        launch(scene: "st-pick")
        let badge = element("autopilot.pick.badge.0")
        XCTAssertTrue(badge.waitForExistence(timeout: 15))
        let other = element("autopilot.pick.attempt.0.2")
        XCTAssertTrue(other.exists)
        let pick = element("autopilot.pick")
        for _ in 0..<12 where other.frame.maxY > pick.frame.maxY {
            pick.scroll(byDeltaX: 0, deltaY: -200)
        }
        other.click()
        // Full size, where Use This Capture picks it.
        let use = element("studio.viewer.action")
        XCTAssertTrue(use.waitForExistence(timeout: 5))
        use.click()
        element("studio.viewer.close").click()
        XCTAssertTrue(waitForText(of: badge, toBe: "Your pick"), text(of: badge))
        app.buttons["autopilot.guided.usePicks"].click()
        XCTAssertTrue(pick.waitForNonExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.guided.making.line").waitForExistence(timeout: 5), "Making it goes on to the design")
    }

    /// The full-size viewer zooms like Review & Push's: a double-click
    /// goes to 200%, Fit goes back.
    func testTheFullSizeViewerZooms() {
        launch(scene: "st-pick")
        let other = element("autopilot.pick.attempt.0.2")
        XCTAssertTrue(other.waitForExistence(timeout: 15))
        let pick = element("autopilot.pick")
        for _ in 0..<12 where other.frame.maxY > pick.frame.maxY {
            pick.scroll(byDeltaX: 0, deltaY: -200)
        }
        other.click()

        let zoom = element("studio.viewer.zoom")
        XCTAssertTrue(zoom.waitForExistence(timeout: 5))
        XCTAssertFalse(element("studio.viewer.zoom.percent").exists, "It opens at fit")
        zoom.doubleClick()
        let percent = element("studio.viewer.zoom.percent")
        XCTAssertTrue(percent.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: percent).contains("200%"), text(of: percent))

        app.buttons["studio.viewer.zoom.fit"].click()
        XCTAssertTrue(percent.waitForNonExistence(timeout: 5))
        element("studio.viewer.close").click()
        XCTAssertTrue(element("studio.viewer").waitForNonExistence(timeout: 5))
    }

    func testUsingADirectionMovesOnToLocalize() {
        launch(scene: "st-choose")
        let choose = app.buttons.matching(identifier: "autopilot.guided.choose.look.use").firstMatch
        XCTAssertTrue(choose.waitForExistence(timeout: 15))
        choose.click()
        let use = element("autopilot.guided.useChoices")
        XCTAssertTrue(waitUntil { use.isEnabled }, "A look is chosen")
        use.click()
        XCTAssertTrue(element("autopilot.guided.making.checking").waitForExistence(timeout: 5), "Making it checks every image")
    }

    func testARevisedDirectionSaysSo() {
        launch(scene: "st-choose-rev")
        let revised = element("autopilot.guided.choose.look.revised")
        XCTAssertTrue(revised.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: revised), "Revised")
    }

    // MARK: - Design project

    func testConnectADesignProjectWithStarters() {
        launch(scene: "st-design")
        XCTAssertTrue(element("designProject.sheet").waitForExistence(timeout: 15))
        let connect = app.buttons["designProject.connect"]
        // Claude Design needs a name or link first.
        XCTAssertFalse(connect.isEnabled)
        element("designProject.kind.none").click()
        XCTAssertTrue(connect.isEnabled)
        connect.click()
        XCTAssertTrue(element("designProject.sheet").waitForNonExistence(timeout: 5))
    }

    // MARK: - Helpers

    /// What to make → Look → the plan, with iPhone Duo left out first: the
    /// pretend Mac has no iPhone Duo simulator, and Start waits for one.
    /// Start Autopilot, once it can go.
    private func goToThePlan() -> XCUIElement {
        let duo = element("autopilot.guided.make.device.iphone_duo")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        if duo.isSelected { duo.click() }
        XCTAssertTrue(waitUntil { !duo.isSelected }, "iPhone Duo left out")
        openThePlan()
        let start = element("autopilot.guided.start")
        XCTAssertTrue(waitUntil(timeout: 10) { start.isEnabled }, "Start can go")
        return start
    }

    /// What to make → Look → the plan.
    private func openThePlan() {
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        next.click()
        XCTAssertTrue(element("autopilot.guided.look.noteCard").waitForExistence(timeout: 5), "At Look")
        next.click()
        XCTAssertTrue(element("autopilot.guided.plan.timeline").waitForExistence(timeout: 5), "At the plan")
    }

    /// Scrolls the guided sheet's step until `target` is inside what it
    /// shows.
    private func reveal(_ target: XCUIElement) {
        let step = element("autopilot.guided.sheet").scrollViews.firstMatch
        guard step.waitForExistence(timeout: 5), target.waitForExistence(timeout: 5) else { return }
        var tries = 0
        while !(target.frame.minY >= step.frame.minY && target.frame.maxY <= step.frame.maxY), tries < 12 {
            step.scroll(byDeltaX: 0, deltaY: target.frame.minY < step.frame.minY ? 200 : -200)
            tries += 1
        }
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        return condition()
    }

    private func waitForText(of element: XCUIElement, toBe expected: String, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if text(of: element) == expected { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        return false
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
