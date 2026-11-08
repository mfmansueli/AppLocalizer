//
//  SceneSnapshotUITests.swift
//  AppLocalizerUITests
//

import XCTest

/// Photographs DEBUG scenes to compare with the design canvas's boards:
/// one window screenshot per scene named in `SNAP_SCENES` (comma
/// separated, `TEST_RUNNER_SNAP_SCENES=ap-look,ap-plan xcodebuild …`), as
/// attachments of the result bundle. Skipped when the variable isn't set.
@MainActor
final class SceneSnapshotUITests: XCTestCase {
    func testPhotographTheScenes() throws {
        let scenes = ProcessInfo.processInfo.environment["SNAP_SCENES"]?.split(separator: ",").map(String.init) ?? []
        try XCTSkipIf(scenes.isEmpty, "Set SNAP_SCENES to photograph scenes")
        let settle = ProcessInfo.processInfo.environment["SNAP_SETTLE"].flatMap(Double.init) ?? 3
        for scene in scenes {
            let app = XCUIApplication()
            app.launch(debugScene: scene)
            let window = app.windows.firstMatch
            XCTAssertTrue(window.waitForExistence(timeout: 20), "\(scene): a window")
            RunLoop.current.run(until: .now.addingTimeInterval(settle))
            let attachment = XCTAttachment(screenshot: window.screenshot())
            attachment.name = scene
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }
}
