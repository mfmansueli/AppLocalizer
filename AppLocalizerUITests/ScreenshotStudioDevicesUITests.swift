//
//  ScreenshotStudioDevicesUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Screenshots → Preview and Autopilot on every device and language the
/// app supports, driven through the every-device DEBUG scenes in
/// `StudioDebugScenes` (Lumen with a watch app, a visionOS version and
/// three languages the App Store page doesn't have yet).
@MainActor
final class ScreenshotStudioDevicesUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Plan

    func testThePlanListsEveryDeviceTheAppRunsOn() {
        launch(scene: "st-plan-all")
        let found = element("autopilot.plan.found")
        XCTAssertTrue(found.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: found).hasPrefix("Found in Lumen"))
        for device in ["iphone", "iPad", "watch", "vision"] {
            XCTAssertTrue(element("autopilot.plan.\(device)").exists, device)
        }
        let scope = element("autopilot.scope")
        XCTAssertTrue(text(of: scope).contains("Apple Watch"))
        XCTAssertTrue(text(of: scope).contains("Apple Vision Pro"))

        element("autopilot.plan.watch").click()
        XCTAssertTrue(waitUntil { !self.text(of: scope).contains("Apple Watch") })
        XCTAssertTrue(text(of: scope).contains("Apple Vision Pro"))
    }

    func testTheNewLanguagesCanBeLeftOutOfThePlan() throws {
        launch(scene: "st-plan-all")
        let newLanguages = element("autopilot.plan.newLanguages")
        XCTAssertTrue(newLanguages.waitForExistence(timeout: 15))
        let scope = element("autopilot.scope")
        let before = try XCTUnwrap(languageCount(in: text(of: scope)))
        newLanguages.click()
        XCTAssertTrue(waitUntil { self.languageCount(in: self.text(of: scope)) == before - 3 }, "Polish, Turkish and Hebrew")
    }

    func testAWatchAppOnAppStoreConnectAddsAppleWatch() {
        launch(scene: "st-asc-watch")
        XCTAssertTrue(element("studio.device.APP_WATCH_ULTRA").waitForExistence(timeout: 15))
        app.buttons["studio.autopilot.run"].click()
        let watch = element("autopilot.plan.watch")
        XCTAssertTrue(watch.waitForExistence(timeout: 5))
        XCTAssertTrue(watch.label.contains("required: the 1.4 build has an Apple Watch app"))
        XCTAssertTrue(text(of: element("autopilot.plan.found")).hasSuffix("on App Store Connect: its build has an Apple Watch app."))
    }

    // MARK: - Pick, choose, localize

    func testWatchPicksApplyToEveryLanguage() {
        launch(scene: "st-pick-all")
        XCTAssertTrue(element("autopilot.pick.note").waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: element("autopilot.pick.note")).contains("Apple Vision Pro use the same moments as iPhone"))
        XCTAssertTrue(element("autopilot.pick.watch").exists)
    }

    func testEachDirectionShowsTheVisionProWindowAndTheWatch() {
        launch(scene: "st-choose-all")
        let thumbnails = app.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnails").firstMatch
        XCTAssertTrue(thumbnails.waitForExistence(timeout: 15))
        XCTAssertTrue(thumbnails.label.contains("an Apple Vision Pro screenshot"))
        XCTAssertTrue(thumbnails.label.contains("an Apple Watch capture"))
        XCTAssertTrue(app.buttons.matching(identifier: "autopilot.direction.use").firstMatch.exists)
    }

    func testTheNewLanguagesAreLocalizedWithTheRest() {
        launch(scene: "st-loc-all")
        let polish = element("autopilot.localize.pl")
        XCTAssertTrue(polish.waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: polish).hasPrefix("Polish · new"))
        XCTAssertTrue(text(of: element("autopilot.localize.he")).hasPrefix("Hebrew · new"))
    }

    func testTheReadyStageNotesTheNewLanguages() {
        launch(scene: "st-ready-sheet-all")
        XCTAssertTrue(element("autopilot.ready").waitForExistence(timeout: 15))
        XCTAssertTrue(element("autopilot.ready.newLanguages").exists)
    }

    // MARK: - Preview

    func testTheLiveWatchSetWasUploadedByHand() {
        launch(scene: "st-live-watch")
        let note = element("studio.store.note")
        XCTAssertTrue(note.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: note), "Live now · 2 English captures, uploaded by hand")
        XCTAssertTrue(element("studio.device.APP_WATCH_ULTRA").exists)
    }

    func testAppleVisionProWithNothingLiveSaysWhatsNeeded() {
        launch(scene: "st-live-vision")
        XCTAssertTrue(element("studio.store.empty").waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: element("studio.store.note")), "Live now · no Apple Vision Pro screenshots")
    }

    func testTheNewSetSwitchesFromTheWatchToAppleVisionPro() {
        launch(scene: "st-ready-watch")
        let title = element("studio.setCard.title")
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        XCTAssertEqual(text(of: title), "New set")
        element("studio.device.APP_APPLE_VISION_PRO").click()
        XCTAssertTrue(waitUntil { self.text(of: self.element("studio.store.note")).contains("each screen in its own window") })
        XCTAssertFalse(element("studio.store.empty").exists)
    }

    // MARK: - Helpers

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.2))
        }
        return condition()
    }

    /// 13 in "Lumen Journal 1.4 · iPhone, iPad… · 13 languages · …".
    private func languageCount(in scope: String) -> Int? {
        guard let match = scope.firstMatch(of: /(\d+) languages/) else { return nil }
        return Int(match.1)
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
