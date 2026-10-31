//
//  ScreenshotStudioUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Screenshots → Preview, driven through the DEBUG scenes in
/// `StudioDebugScenes` (Lumen Journal with sample runs held at each
/// stage; nothing moves on by itself and nothing leaves the Mac): the App
/// Store preview, the Autopilot strip, the Autopilot sheet and Connect a
/// Design Project.
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
        XCTAssertTrue(element("autopilot.sheet").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.problem").exists)
    }

    func testTheReadySetSwitchesBetweenNewAndLive() {
        launch(scene: "st-ready")
        let title = element("studio.setCard.title")
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: title), "New set")
        XCTAssertTrue(app.buttons["studio.autopilot.reviewPush"].exists)
        app.buttons["studio.set.live"].click()
        XCTAssertTrue(waitForText(of: title, toBe: "Live set"))
        app.buttons["studio.set.new"].click()
        XCTAssertTrue(waitForText(of: title, toBe: "New set"))
    }

    // MARK: - Autopilot sheet

    func testRunAutopilotPlansAndCancelKeepsNothing() {
        launch(scene: "st-home")
        let run = app.buttons["studio.autopilot.run"]
        XCTAssertTrue(run.waitForExistence(timeout: 15))
        run.click()
        XCTAssertTrue(element("autopilot.sheet").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.plan").exists)
        XCTAssertTrue(app.buttons["autopilot.start"].exists)
        app.buttons["autopilot.cancel"].click()
        XCTAssertTrue(element("autopilot.sheet").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["studio.autopilot.run"].waitForExistence(timeout: 5))
    }

    func testStartCopiesThePromptAndCancelRunGoesBackToThePlan() {
        launch(scene: "st-plan")
        let start = app.buttons["autopilot.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        start.click()
        XCTAssertTrue(element("autopilot.wait").waitForExistence(timeout: 5))
        XCTAssertTrue(element("autopilot.wait.copied").exists)
        XCTAssertFalse(text(of: element("autopilot.wait.prompt")).isEmpty)
        app.buttons["autopilot.cancelRun"].click()
        XCTAssertTrue(element("autopilot.plan").waitForExistence(timeout: 5))
    }

    func testThePersonCanKeepTheirScreens() {
        launch(scene: "st-plan")
        let picks = element("autopilot.plan.choosesScreens")
        XCTAssertTrue(picks.waitForExistence(timeout: 15))
        XCTAssertEqual(picks.value as? Int, 1, "Claude Code picks the screens unless the person keeps theirs")
        picks.click()
        app.buttons["autopilot.start"].click()
        let prompt = element("autopilot.wait.prompt")
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        XCTAssertTrue(text(of: prompt).contains("capture the 5 screens"))
        XCTAssertFalse(text(of: prompt).contains("decide which screens"))
    }

    func testThePlanCanDropTheIPad() {
        launch(scene: "st-plan")
        let iPad = element("autopilot.plan.iPad")
        XCTAssertTrue(iPad.waitForExistence(timeout: 15))
        let scope = element("autopilot.scope")
        // "Lumen Journal 1.4 · iPhone and iPad · 12 languages · 5 screens"
        XCTAssertTrue(text(of: scope).contains("iPhone and iPad"))
        iPad.click()
        let deadline = Date.now.addingTimeInterval(5)
        while Date.now < deadline, text(of: scope).contains("iPad") {
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        XCTAssertFalse(text(of: scope).contains("iPad"))
        XCTAssertTrue(text(of: scope).contains("iPhone"))
    }

    func testRetryingWithTheFixClearsTheProblem() {
        launch(scene: "st-fail")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        XCTAssertTrue(element("autopilot.log").exists)
        app.buttons["autopilot.problem.retry"].click()
        XCTAssertTrue(problem.waitForNonExistence(timeout: 5))
    }

    func testPickingAnotherCaptureThenUsingThePicksStartsDesign() {
        launch(scene: "st-pick")
        let picked = element("autopilot.pick.picked.0")
        XCTAssertTrue(picked.waitForExistence(timeout: 15))
        let before = picked.label
        let other = app.buttons["autopilot.pick.other.0.2"]
        XCTAssertTrue(other.exists)
        other.click()
        XCTAssertTrue(waitForLabel(of: picked, toChangeFrom: before))
        app.buttons["autopilot.usePicks"].click()
        XCTAssertTrue(element("autopilot.design").waitForExistence(timeout: 5))
    }

    func testUsingADirectionMovesOnToLocalize() {
        launch(scene: "st-choose")
        let use = app.buttons.matching(identifier: "autopilot.direction.use").firstMatch
        XCTAssertTrue(use.waitForExistence(timeout: 15))
        XCTAssertTrue(element("autopilot.choose.ask").exists)
        use.click()
        XCTAssertTrue(element("autopilot.localize").waitForExistence(timeout: 5))
    }

    func testARevisedDirectionSaysSo() {
        launch(scene: "st-choose-rev")
        XCTAssertTrue(element("autopilot.direction.revised").waitForExistence(timeout: 15))
    }

    func testTheReadyStageListsWhatToCheckAndClosesOnThePreview() {
        launch(scene: "st-ready-sheet")
        XCTAssertTrue(element("autopilot.ready").waitForExistence(timeout: 15))
        XCTAssertTrue(element("autopilot.ready.caption.de-DE.2").exists)
        app.buttons["autopilot.seePreview"].click()
        XCTAssertTrue(element("autopilot.sheet").waitForNonExistence(timeout: 5))
        XCTAssertEqual(text(of: element("studio.setCard.title")), "New set")
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

    private func waitForText(of element: XCUIElement, toBe expected: String, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if text(of: element) == expected { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        return false
    }

    private func waitForLabel(of element: XCUIElement, toChangeFrom old: String, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if element.label != old { return true }
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
