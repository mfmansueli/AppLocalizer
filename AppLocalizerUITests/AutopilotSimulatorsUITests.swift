//
//  AutopilotSimulatorsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Screenshot Autopilot checks this Mac's simulators on the plan before it
/// starts, and installs a missing one; on Making it, a device's card and
/// the log (under Show details) say what happened to it. The DEBUG scenes' pretend Mac has iOS 26.5 and
/// 27.0, so it can't run iPhone Duo (iOS 27.1 or later) until "iOS 27.2"
/// is installed; nothing is downloaded.
@MainActor
final class AutopilotSimulatorsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    /// The plan lists each device's simulator, says what iPhone Duo needs,
    /// keeps Start off until it's there, and installs it.
    func testThePlanChecksThisMacAndInstallsWhatsMissing() {
        app.launch(debugScene: "st-plan")
        goToThePlan()
        let duo = element("autopilot.mac.iphone_duo.status")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: duo).contains("Needs the iOS 27.1 simulator or later"), text(of: duo))
        let iPhone = element("autopilot.mac.iphone.status")
        XCTAssertTrue(text(of: iPhone).contains("iPhone 17 Pro Max · iOS 27.0"), text(of: iPhone))
        let footer = element("autopilot.guided.footer.text")
        XCTAssertTrue(text(of: footer).hasPrefix("Start waits for iPhone Duo"), text(of: footer))
        let start = element("autopilot.guided.start")
        XCTAssertFalse(start.isEnabled, "Start waits for the simulator")

        let install = app.buttons["autopilot.mac.install"]
        reveal(install)
        install.click()
        XCTAssertTrue(wait(until: { self.text(of: duo).contains("iPhone Duo · iOS 27.2") }, timeout: 15), text(of: duo))
        XCTAssertFalse(app.buttons["autopilot.mac.install"].exists)
        XCTAssertFalse(text(of: footer).contains("Start waits"), text(of: footer))
        XCTAssertTrue(wait(until: { start.isEnabled }, timeout: 5), "Start is on once it's installed")
    }

    /// The device's card installs the simulator, and the run tries the
    /// device again.
    func testADeviceWithoutASimulatorIsOneCardThatInstallsIt() {
        app.launch(debugScene: "st-device")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        let headline = "iPhone Duo: no screen can be captured"
        XCTAssertTrue(problem.staticTexts.matching(NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", headline, headline)).firstMatch.exists)
        XCTAssertTrue(app.buttons["autopilot.problem.leaveOut"].exists)
        XCTAssertFalse(app.buttons["autopilot.problem.upload"].exists)
        XCTAssertFalse(app.buttons["autopilot.problem.usePrimary"].exists)
        let retry = app.buttons["autopilot.problem.retry"]
        XCTAssertEqual(retry.title.isEmpty ? retry.label : retry.title, "Retry")

        let install = app.buttons["autopilot.problem.install"]
        XCTAssertTrue(install.waitForExistence(timeout: 10))
        install.click()
        XCTAssertTrue(problem.waitForNonExistence(timeout: 15))
    }

    /// iPhone Duo's simulator starts closed: AppLocalizer opens it itself
    /// (the helper presses Open in Device Hub), and the run tries it again
    /// without a Retry: the card goes, and the log says so.
    func testAClosedIPhoneDuoIsOpenedByAppLocalizer() {
        app.launch(debugScene: "st-duo-closed")
        let log = showDetails()
        XCTAssertTrue(wait(until: {
            self.text(of: log).contains("iPhone Duo was closed: AppLocalizer opened it in Device Hub")
        }, timeout: 15), text(of: log))
        XCTAssertTrue(wait(until: { self.text(of: log).contains("iPhone Duo is open: its screens are captured next") }, timeout: 10), text(of: log))
        XCTAssertTrue(element("autopilot.problem").waitForNonExistence(timeout: 10))
    }

    /// Without Accessibility, the card says what lets AppLocalizer open the
    /// Duo, with System Settings and Device Hub, in place of the
    /// assistant's fix; once the pretend person allows it, the Duo opens and
    /// the run goes on.
    func testWithoutAccessibilityTheDuosCardSaysWhatLetsAppLocalizerOpenIt() {
        app.launch(debugScene: "st-duo-access")
        let status = element("autopilot.problem.duo")
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        XCTAssertTrue(wait(until: {
            self.text(of: status).hasPrefix("Closed: allow AppLocalizer in Privacy & Security › Accessibility, and it opens iPhone Duo itself.")
        }, timeout: 10), text(of: status))
        let note = element("autopilot.problem.note")
        XCTAssertTrue(text(of: note).hasPrefix("AppLocalizer uses it only to press Open in iPhone Duo’s window in Device Hub"), text(of: note))
        XCTAssertTrue(app.buttons["autopilot.problem.accessibility"].exists)
        XCTAssertTrue(app.buttons["autopilot.problem.deviceHub"].exists)
        XCTAssertFalse(element("autopilot.problem.fix").exists)
        XCTAssertTrue(app.buttons["autopilot.problem.leaveOut"].exists)

        let log = showDetails()
        XCTAssertTrue(wait(until: {
            self.text(of: log).contains("AppLocalizer needs Accessibility to open iPhone Duo: macOS asked for it")
        }, timeout: 5), text(of: log))
        XCTAssertTrue(wait(until: {
            self.text(of: log).contains("iPhone Duo was closed: AppLocalizer opened it in Device Hub")
        }, timeout: 20), text(of: log))
        XCTAssertTrue(element("autopilot.problem").waitForNonExistence(timeout: 10))
    }

    /// With a helper that can't open the Duo yet (version 4), the card asks
    /// to save it again; once the pretend person opens the Duo in Device
    /// Hub, the run tries it again by itself.
    func testAnOpenedIPhoneDuoIsTriedAgainWithoutRetry() {
        app.launch(debugScene: "st-duo-opens")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        XCTAssertTrue(problem.waitForNonExistence(timeout: 15))
        let log = showDetails()
        XCTAssertTrue(wait(until: { self.text(of: log).contains("iPhone Duo is open: its screens are captured next") }, timeout: 5), text(of: log))
        XCTAssertFalse(text(of: log).contains("AppLocalizer opened it"), text(of: log))
    }

    /// A stuck iPhone Duo (its SpringBoard crashed, a spinner on its inner
    /// display) is restarted by AppLocalizer, comes back closed, and is
    /// opened.
    func testAStuckIPhoneDuoIsRestartedAndOpened() {
        app.launch(debugScene: "st-duo-stuck")
        let log = showDetails()
        XCTAssertTrue(wait(until: {
            self.text(of: log).contains("iPhone Duo was stuck, its SpringBoard crashed: AppLocalizer restarted it")
        }, timeout: 15), text(of: log))
        XCTAssertTrue(wait(until: {
            self.text(of: log).contains("iPhone Duo was closed: AppLocalizer opened it in Device Hub")
        }, timeout: 15), text(of: log))
        XCTAssertTrue(element("autopilot.problem").waitForNonExistence(timeout: 10))
    }

    /// With a helper from before it could look at iPhone Duo, the card
    /// keeps the assistant's fix, says how to restart a stuck Duo by hand,
    /// and asks to save the helper again.
    func testWithAnOlderHelperTheDuosCardSaysWhatToDoByHand() {
        app.launch(debugScene: "st-duo-old")
        XCTAssertTrue(element("autopilot.problem").waitForExistence(timeout: 15))
        let fix = element("autopilot.problem.fix")
        XCTAssertTrue(fix.waitForExistence(timeout: 10))
        XCTAssertEqual(text(of: fix), "Open iPhone Duo in Device Hub.")
        let note = element("autopilot.problem.note")
        XCTAssertTrue(text(of: note).contains("If its inner display shows only a spinner, shut it down there"), text(of: note))
        XCTAssertTrue(text(of: note).hasSuffix("Then retry; leaving it out finishes the run without it."), text(of: note))
        let why = element("autopilot.problem.duoHelperNote")
        XCTAssertTrue(why.waitForExistence(timeout: 10))
        XCTAssertTrue(text(of: why).hasPrefix("Save the helper again so AppLocalizer can open iPhone Duo"), text(of: why))
        let save = app.buttons["autopilot.problem.duoHelper"]
        XCTAssertTrue(save.exists)
        XCTAssertEqual(save.title.isEmpty ? save.label : save.title, "Save the Helper Again…")
        XCTAssertTrue(app.buttons["autopilot.problem.deviceHub"].exists)
    }

    /// The plan says iPhone Duo is closed and AppLocalizer opens it when the
    /// run needs it; Open Now opens it before Start.
    func testThePlanSaysAppLocalizerOpensIPhoneDuo() {
        app.launch(debugScene: "st-plan-duo")
        goToThePlan()
        let duo = element("autopilot.mac.iphone_duo.status")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        XCTAssertTrue(wait(until: { self.text(of: duo).contains("closed: AppLocalizer opens it when the run needs it") }, timeout: 10), text(of: duo))
        XCTAssertTrue(text(of: duo).contains("iPhone Duo · iOS 27.2"), text(of: duo))
        XCTAssertFalse(app.buttons["autopilot.mac.deviceHub"].exists)
        let openNow = app.buttons["autopilot.mac.openDuo"]
        XCTAssertTrue(openNow.exists)
        // The row sits under the sheet's footer until the plan scrolls.
        reveal(openNow)
        openNow.click()
        XCTAssertTrue(wait(until: { self.text(of: duo).contains("iOS 27.2 · open") }, timeout: 10), text(of: duo))
        XCTAssertFalse(openNow.exists)
    }

    /// Before Start, the plan says when AppLocalizer needs Accessibility to
    /// open iPhone Duo, with a way to System Settings.
    func testThePlanSaysWhenAppLocalizerNeedsAccessibility() {
        app.launch(debugScene: "st-plan-duo-access")
        goToThePlan()
        let duo = element("autopilot.mac.iphone_duo.status")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        XCTAssertTrue(wait(until: {
            self.text(of: duo).contains("Closed. Allow AppLocalizer in Privacy & Security › Accessibility")
        }, timeout: 10), text(of: duo))
        XCTAssertTrue(app.buttons["autopilot.mac.accessibility"].exists)
        XCTAssertFalse(app.buttons["autopilot.mac.openDuo"].exists)
    }

    /// Leaving iPhone Duo out closes its card.
    /// Bruma's run: no Mac screen could be captured because the UI tests
    /// didn't build for macOS. The card said to retry "once this Mac can run
    /// the Mac simulator"; it's a change to the project, and says so.
    func testAMacThatNeedsAProjectChangeSaysSo() {
        app.launch(debugScene: "st-mac-project")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        let label = "What to change in the project:"
        XCTAssertTrue(problem.staticTexts.matching(NSPredicate(format: "value == %@ OR label == %@", label, label)).firstMatch.exists)
        let note = element("autopilot.problem.note")
        XCTAssertTrue(note.exists)
        let text = (note.value as? String) ?? note.label
        XCTAssertTrue(text.hasPrefix("This is a change to the project"), text)
        XCTAssertFalse(text.contains("simulator"), text)
        XCTAssertTrue(app.buttons["autopilot.problem.leaveOut"].exists)
        XCTAssertFalse(app.buttons["autopilot.problem.helper"].exists)
        XCTAssertFalse(app.buttons["autopilot.problem.install"].exists)
    }

    /// Bruma's run, only its Mac left to decide, said "about 52 min left"
    /// and "the rest keeps going" with nothing going on.
    func testOnlyTheMacLeftWaitsOnThePerson() {
        app.launch(debugScene: "st-mac-alone")
        XCTAssertTrue(element("autopilot.problem").waitForExistence(timeout: 15))
        let line = element("autopilot.guided.making.line")
        XCTAssertTrue(line.exists)
        let lineText = (line.value as? String) ?? line.label
        XCTAssertTrue(lineText.hasSuffix("wait on you"), lineText)
        XCTAssertFalse(lineText.contains("min left"), lineText)
        let footer = element("autopilot.guided.footer.text")
        let footerText = (footer.value as? String) ?? footer.label
        XCTAssertTrue(footerText.hasPrefix("Everything else is in."), footerText)
    }

    func testLeavingTheDeviceOutClosesItsCard() {
        app.launch(debugScene: "st-device")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        app.buttons["autopilot.problem.leaveOut"].click()
        XCTAssertTrue(problem.waitForNonExistence(timeout: 5))
    }

    /// The sheet opens a planned run at What to make: on to the plan.
    private func goToThePlan() {
        let next = element("autopilot.guided.next")
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        next.click()
        XCTAssertTrue(element("autopilot.guided.back").waitForExistence(timeout: 5), "At Look")
        element("autopilot.guided.next").click()
        XCTAssertTrue(element("autopilot.guided.plan.timeline").waitForExistence(timeout: 5), "At the plan")
    }

    /// Making it keeps the log under Show details: shows it. The link moves
    /// up when a card above it goes (the Duo opened), so a click that lands
    /// where it was is tried again.
    private func showDetails() -> XCUIElement {
        let details = element("autopilot.guided.making.details")
        XCTAssertTrue(details.waitForExistence(timeout: 15))
        let log = element("autopilot.log")
        var tries = 0
        while !log.waitForExistence(timeout: tries == 0 ? 0.5 : 3), tries < 3 {
            // Below the problem cards, under the footer until scrolled to.
            reveal(details)
            details.click()
            tries += 1
        }
        XCTAssertTrue(log.exists, "The log is shown")
        return log
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
