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

    // MARK: - What to make

    func testWhatToMakeListsEveryDeviceTheAppRunsOn() {
        launch(scene: "st-plan-all")
        let watch = element("autopilot.guided.make.device.watch")
        XCTAssertTrue(watch.waitForExistence(timeout: 15))
        for device in ["iphone", "iPad", "watch", "vision"] {
            XCTAssertTrue(element("autopilot.guided.make.device.\(device)").exists, device)
        }
        let vision = element("autopilot.guided.make.device.vision")
        XCTAssertTrue(watch.isSelected)
        XCTAssertTrue(vision.isSelected)
        let footer = element("autopilot.guided.footer.text")
        let before = text(of: footer)

        watch.click()
        XCTAssertTrue(waitUntil { !watch.isSelected })
        XCTAssertTrue(vision.isSelected)
        XCTAssertTrue(waitUntil { self.text(of: footer) != before }, "Fewer screenshots without the watch: \(text(of: footer))")
    }

    func testTheNewLanguagesCanBeLeftOut() throws {
        launch(scene: "st-plan-all")
        let newLanguages = element("autopilot.guided.make.newLanguages")
        XCTAssertTrue(newLanguages.waitForExistence(timeout: 15))
        XCTAssertTrue(newLanguages.label.contains("Polish"), newLanguages.label)
        XCTAssertTrue(newLanguages.label.contains("Hebrew"), newLanguages.label)
        let footer = element("autopilot.guided.footer.text")
        let before = try XCTUnwrap(languageCount(in: text(of: footer)), text(of: footer))
        newLanguages.click()
        XCTAssertTrue(waitUntil { self.languageCount(in: self.text(of: footer)) == before - 3 }, "Polish, Turkish and Hebrew")
    }

    func testAWatchAppOnAppStoreConnectAddsAppleWatch() {
        launch(scene: "st-asc-watch")
        XCTAssertTrue(element("studio.device.APP_WATCH_ULTRA").waitForExistence(timeout: 15))
        app.buttons["studio.autopilot.run"].click()
        let watch = element("autopilot.guided.make.device.watch")
        XCTAssertTrue(watch.waitForExistence(timeout: 5))
        XCTAssertTrue(watch.isSelected, "The build's watch app puts Apple Watch in the run")
    }

    // MARK: - Pick and choose

    func testWatchPicksApplyToEveryLanguage() {
        launch(scene: "st-pick-all")
        XCTAssertTrue(element("autopilot.pick.note").waitForExistence(timeout: 15))
        XCTAssertTrue(text(of: element("autopilot.pick.note")).contains("Picks apply to every language; iPad and Apple Vision Pro use the same moments."))
        element("autopilot.pick.device").radioButtons["Apple Watch"].click()
        XCTAssertTrue(element("autopilot.pick.watch.0").waitForExistence(timeout: 5))
    }

    func testEachDirectionShowsTheVisionProWindowAndTheWatch() {
        launch(scene: "st-choose-all")
        let thumbnails = app.descendants(matching: .any).matching(identifier: "autopilot.direction.thumbnails").firstMatch
        XCTAssertTrue(thumbnails.waitForExistence(timeout: 15))
        XCTAssertTrue(thumbnails.label.contains("an Apple Vision Pro screenshot"), thumbnails.label)
        XCTAssertTrue(thumbnails.label.contains("an Apple Watch capture"), thumbnails.label)
        XCTAssertTrue(app.buttons.matching(identifier: "autopilot.guided.choose.look.use").firstMatch.exists)
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

    /// 15 in "You’ll get 135 screenshots in 15 languages."
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
