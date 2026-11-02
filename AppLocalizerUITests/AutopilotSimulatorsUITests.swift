//
//  AutopilotSimulatorsUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Screenshot Autopilot checks this Mac's simulators before it starts, and
/// installs a missing one. The DEBUG scenes' pretend Mac has iOS 26.5 and
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
    /// and installs it.
    func testThePlanChecksThisMacAndInstallsWhatsMissing() {
        app.launch(debugScene: "st-plan")
        let duo = element("autopilot.mac.iphone_duo")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: duo).contains("Needs the iOS 27.1 simulator or later"), text(of: duo))
        XCTAssertTrue(text(of: element("autopilot.mac.iphone")).contains("iPhone 17 Pro Max · iOS 27.0"), text(of: element("autopilot.mac.iphone")))
        let footer = element("autopilot.footer.text")
        XCTAssertTrue(text(of: footer).contains("can’t capture iPhone Duo yet"), text(of: footer))

        app.buttons["autopilot.mac.install"].click()
        XCTAssertTrue(wait(until: { self.text(of: duo).contains("iPhone Duo · iOS 27.2") }, timeout: 15), text(of: duo))
        XCTAssertFalse(app.buttons["autopilot.mac.install"].exists)
        XCTAssertFalse(text(of: footer).contains("can’t capture"), text(of: footer))
    }

    /// Starting without the simulator puts one problem on the device
    /// before the assistant tries it.
    func testStartingWithoutASimulatorReportsTheDeviceOnce() {
        app.launch(debugScene: "st-plan")
        XCTAssertTrue(element("autopilot.mac.iphone_duo").waitForExistence(timeout: 15))
        app.buttons["autopilot.start"].click()
        // While it runs, the row's spinner makes it a progress indicator.
        let capture = element("autopilot.stage.capture")
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
        XCTAssertTrue(wait(until: { capture.label.contains("Capture, 1 problem needs you") }, timeout: 5), capture.label)
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
        let log = element("autopilot.log")
        XCTAssertTrue(log.waitForExistence(timeout: 15))
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

        let log = element("autopilot.log")
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
        let log = element("autopilot.log")
        XCTAssertTrue(wait(until: { self.text(of: log).contains("iPhone Duo is open: its screens are captured next") }, timeout: 5), text(of: log))
        XCTAssertFalse(text(of: log).contains("AppLocalizer opened it"), text(of: log))
    }

    /// A stuck iPhone Duo (its SpringBoard crashed, a spinner on its inner
    /// display) is restarted by AppLocalizer, comes back closed, and is
    /// opened.
    func testAStuckIPhoneDuoIsRestartedAndOpened() {
        app.launch(debugScene: "st-duo-stuck")
        let log = element("autopilot.log")
        XCTAssertTrue(log.waitForExistence(timeout: 15))
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
        let duo = element("autopilot.mac.iphone_duo")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        XCTAssertTrue(wait(until: { self.text(of: duo).contains("Closed: AppLocalizer opens it when the run needs it.") }, timeout: 10), text(of: duo))
        XCTAssertTrue(text(of: duo).contains("iPhone Duo · iOS 27.2"), text(of: duo))
        XCTAssertFalse(app.buttons["autopilot.mac.deviceHub"].exists)
        let openNow = app.buttons["autopilot.mac.openDuo"]
        XCTAssertTrue(openNow.exists)
        // The row sits under the sheet's footer until the plan scrolls.
        element("autopilot.plan").scroll(byDeltaX: 0, deltaY: -600)
        openNow.click()
        XCTAssertTrue(wait(until: { self.text(of: duo).contains("Open: ready to capture.") }, timeout: 10), text(of: duo))
        XCTAssertFalse(openNow.exists)
    }

    /// Before Start, the plan says when AppLocalizer needs Accessibility to
    /// open iPhone Duo, with a way to System Settings.
    func testThePlanSaysWhenAppLocalizerNeedsAccessibility() {
        app.launch(debugScene: "st-plan-duo-access")
        let duo = element("autopilot.mac.iphone_duo")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        XCTAssertTrue(wait(until: {
            self.text(of: duo).contains("Closed: allow AppLocalizer in Privacy & Security › Accessibility")
        }, timeout: 10), text(of: duo))
        XCTAssertTrue(app.buttons["autopilot.mac.accessibility"].exists)
        XCTAssertFalse(app.buttons["autopilot.mac.openDuo"].exists)
    }

    /// Leaving iPhone Duo out closes its card.
    func testLeavingTheDeviceOutClosesItsCard() {
        app.launch(debugScene: "st-device")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        app.buttons["autopilot.problem.leaveOut"].click()
        XCTAssertTrue(problem.waitForNonExistence(timeout: 5))
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
