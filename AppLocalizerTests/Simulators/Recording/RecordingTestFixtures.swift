//
//  RecordingTestFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// A recording of iPhone Duo's inner display during a UI test that opens
/// the Streak sheet and attaches its screenshot, shaped like the helper's
/// output and `xcresulttool`'s JSON on a real run (Alba, 2026-11-02): the
/// sheet's label was found at `readySince`, and the test attached its
/// screenshot two seconds later, at `attachedAt`.
enum RecordingTestFixtures {
    /// `DebugSimulators`' iPhone Duo.
    static let udid = "00000000-0000-0000-0000-000000000004"
    static let folder = "/var/folders/xy/T/applocalizer-recording.Ab12Cd34Ef"
    static let bundle = "/Users/sam/Lumen/build/streak.xcresult"
    static let test = "ScreenshotUITests/testStreak()"
    static let readySince = 1_793_626_246.228
    static let attachedAt = 1_793_626_248.421

    /// The Home Screen, the app opening the sheet, the sheet (the frame
    /// kept), and the app closing after the test's screenshot.
    static let frames = [
        RecordedFrame(file: "frame-1793626240.200-1793626240.800.png", start: 1_793_626_240.2, end: 1_793_626_240.8, lastSeen: 1_793_626_244.9),
        RecordedFrame(file: "frame-1793626245.700-1793626246.300.png", start: 1_793_626_245.7, end: 1_793_626_246.3, lastSeen: 1_793_626_246.3),
        RecordedFrame(file: "frame-1793626247.767-1793626248.305.png", start: 1_793_626_247.767, end: 1_793_626_248.305, lastSeen: 1_793_626_248.305),
        RecordedFrame(file: "frame-1793626248.310-1793626248.900.png", start: 1_793_626_248.31, end: 1_793_626_248.9, lastSeen: 1_793_626_248.9),
    ]

    /// What `record-display` printed for `frames`.
    static var recordingLines: [String] {
        [
            "folder \(folder)",
            "frame 1793626240.200 1793626240.800 \(frames[0].file)",
            "same 1793626244.900",
            "frame 1793626245.700 1793626246.300 \(frames[1].file)",
            "frame 1793626247.767 1793626248.305 \(frames[2].file)",
            "frame 1793626248.310 1793626248.900 \(frames[3].file)",
        ]
    }

    /// `xcresulttool get test-results tests`: the bundle ran `testStreak()`
    /// (and, with `topics`, `testTopics()` too).
    static func testsJSON(topics: Bool = false) -> String {
        let topicsNode = topics ? #", {"name": "testTopics()", "nodeIdentifier": "ScreenshotUITests/testTopics()", "nodeType": "Test Case"}"# : ""
        return #"""
        {"devices": [{"deviceId": "\#(udid)", "deviceName": "iPhone Duo"}],
         "testNodes": [{"name": "Lumen", "nodeType": "Test Plan", "children": [
           {"name": "LumenUITests", "nodeType": "UI test bundle", "children": [
             {"name": "ScreenshotUITests", "nodeType": "Test Suite", "children": [
               {"name": "testStreak()", "nodeIdentifier": "\#(test)", "nodeType": "Test Case", "result": "Passed"}\#(topicsNode)
             ]}]}]}]}
        """#
    }

    /// `xcresulttool get test-results activities` for a test that attached
    /// `name` at `time`, its step before starting at `readySince`, on
    /// `device`.
    static func activitiesJSON(
        test: String = test, name: String = "streak", time: Double = attachedAt, readySince: Double = readySince,
        device: String = udid, titled: Bool = true
    ) -> String {
        let title = titled ? "Added attachment named '\(name)'" : "Attachment"
        return #"""
        {"testIdentifier": "\#(test)", "testName": "testStreak()",
         "testRuns": [{"device": {"deviceId": "\#(device)", "deviceName": "iPhone Duo"}, "activities": [
           {"title": "Set Up", "startTime": \#(time - 8.3)},
           {"title": "Open com.northpier.lumen", "startTime": \#(time - 8.2), "childActivities": [
             {"title": "Launch com.northpier.lumen", "startTime": \#(time - 8.2)}]},
           {"title": "Tap \"streakButton\" Button", "startTime": \#(readySince - 1.2)},
           {"title": "Waiting 5.0s for \"12\" StaticText to exist", "startTime": \#(readySince - 0.6), "childActivities": [
             {"title": "Checking existence of `\"12\" StaticText`", "startTime": \#(readySince)}]},
           {"title": "\#(title)", "startTime": \#(time), "activityType": "com.apple.dt.xctest.activity-type.attachmentContainer",
            "attachments": [{"name": "\#(name)_0_6D546067-CC4E-4BBC-9CCE-6BB2198D5680.png", "timestamp": \#(time)}],
            "childActivities": [{"title": "\#(name)", "startTime": \#(time)}]},
           {"title": "Tear Down", "startTime": \#(time + 0.001)}
         ]}]}
        """#
    }

    /// A full-size frame of the inner display, open, showing the app.
    static let png = DebugSimulators.png(.showing, width: 2853, height: 2007)
}
#endif
