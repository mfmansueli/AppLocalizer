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

    /// iPhone Duo's simulator starts closed: AppLocalizer sees that it's
    /// closed, the card opens Device Hub and says the run goes on by itself
    /// once it's open, in place of the assistant's fix.
    func testAClosedIPhoneDuoOpensDeviceHub() {
        app.launch(debugScene: "st-duo-closed")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        let status = element("autopilot.problem.duo")
        XCTAssertTrue(wait(until: { self.text(of: status).hasPrefix("Closed: open it in Device Hub.") }, timeout: 10), text(of: status))
        XCTAssertTrue(text(of: status).hasSuffix("Once it’s open, the run captures it by itself."), text(of: status))
        let note = element("autopilot.problem.note")
        XCTAssertTrue(text(of: note).hasPrefix("In Device Hub, select iPhone Duo"), text(of: note))
        XCTAssertTrue(text(of: note).hasSuffix("AppLocalizer restarts it when it’s stuck; leaving it out finishes the run without it."), text(of: note))
        XCTAssertFalse(element("autopilot.problem.fix").exists)
        XCTAssertTrue(app.buttons["autopilot.problem.deviceHub"].exists)
        XCTAssertFalse(app.buttons["autopilot.problem.install"].exists)
        XCTAssertTrue(app.buttons["autopilot.problem.retry"].exists)
        XCTAssertTrue(app.buttons["autopilot.problem.leaveOut"].exists)
    }

    /// Once the person opens iPhone Duo in Device Hub, the run tries it
    /// again by itself: the card goes, and the log says so.
    func testAnOpenedIPhoneDuoIsTriedAgainWithoutRetry() {
        app.launch(debugScene: "st-duo-opens")
        let problem = element("autopilot.problem")
        XCTAssertTrue(problem.waitForExistence(timeout: 15))
        XCTAssertTrue(problem.waitForNonExistence(timeout: 15))
        let log = element("autopilot.log")
        XCTAssertTrue(wait(until: { self.text(of: log).contains("iPhone Duo is open: its screens are captured next") }, timeout: 5), text(of: log))
    }

    /// A stuck iPhone Duo (its SpringBoard crashed, a spinner on its inner
    /// display) is restarted by AppLocalizer, and comes back closed.
    func testAStuckIPhoneDuoIsRestarted() {
        app.launch(debugScene: "st-duo-stuck")
        XCTAssertTrue(element("autopilot.problem").waitForExistence(timeout: 15))
        let log = element("autopilot.log")
        XCTAssertTrue(wait(until: {
            self.text(of: log).contains("iPhone Duo was stuck, its SpringBoard crashed: AppLocalizer restarted it")
        }, timeout: 15), text(of: log))
        let status = element("autopilot.problem.duo")
        XCTAssertTrue(wait(until: { self.text(of: status).hasPrefix("Closed: open it in Device Hub.") }, timeout: 10), text(of: status))
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
        XCTAssertTrue(text(of: why).hasPrefix("Save the helper again so AppLocalizer can see whether iPhone Duo is open"), text(of: why))
        let save = app.buttons["autopilot.problem.duoHelper"]
        XCTAssertTrue(save.exists)
        XCTAssertEqual(save.title.isEmpty ? save.label : save.title, "Save the Helper Again…")
        XCTAssertTrue(app.buttons["autopilot.problem.deviceHub"].exists)
    }

    /// The plan says whether iPhone Duo's simulator is open, and to open it
    /// before Start.
    func testThePlanSaysWhetherIPhoneDuoIsOpen() {
        app.launch(debugScene: "st-plan-duo")
        let duo = element("autopilot.mac.iphone_duo")
        XCTAssertTrue(duo.waitForExistence(timeout: 15))
        XCTAssertTrue(wait(until: { self.text(of: duo).contains("Closed: open it in Device Hub before Start") }, timeout: 10), text(of: duo))
        XCTAssertTrue(text(of: duo).contains("iPhone Duo · iOS 27.2"), text(of: duo))
        XCTAssertTrue(app.buttons["autopilot.mac.deviceHub"].exists)
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
