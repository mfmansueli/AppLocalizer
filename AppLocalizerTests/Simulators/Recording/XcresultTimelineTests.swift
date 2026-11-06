//
//  XcresultTimelineTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A UI test result bundle's JSON read for when each test took the
/// screenshots it attached.
@Suite("UI test result timeline")
struct XcresultTimelineTests {
    @Test func theTestCasesAreFoundUnderTheirPlanBundleAndSuite() {
        let ids = XcresultTimeline.testIDs(in: Data(RecordingTestFixtures.testsJSON(topics: true).utf8))
        #expect(ids == [RecordingTestFixtures.test, "ScreenshotUITests/testTopics()"])
    }

    /// The step before the screenshot is the latest that started before it,
    /// nested or not; the screenshot's own and later steps don't count.
    @Test func eachScreenshotHasItsTimeAndTheStepBefore() {
        let screenshots = XcresultTimeline.screenshots(in: Data(RecordingTestFixtures.activitiesJSON().utf8))
        #expect(screenshots == [TestScreenshot(
            test: RecordingTestFixtures.test, name: "streak", time: RecordingTestFixtures.attachedAt,
            readySince: RecordingTestFixtures.readySince, deviceID: RecordingTestFixtures.udid
        )])
    }

    /// Without "Added attachment named …", the file's name without the
    /// `_0_<UUID>.png` XCTest adds.
    @Test func anAttachmentIsNamedByItsFileOtherwise() {
        let json = RecordingTestFixtures.activitiesJSON(name: "topics", titled: false)
        #expect(XcresultTimeline.screenshots(in: Data(json.utf8)).map(\.name) == ["topics"])
    }

    /// MB Admin's iPhone Duo bundle: beside the test's own screenshots,
    /// XCTest's synthesized events, UI snapshots, a screen recording and
    /// texts, each of which became a capture to check.
    @Test func onlyTheTestsOwnScreenshotsCount() {
        let json = #"""
        {"testIdentifier": "SecondaryScreensUITests/testCompare()",
         "testRuns": [{"device": {"deviceId": "DUO"}, "activities": [
           {"title": "Start Screen Recording", "startTime": 10,
            "attachments": [{"name": "Screen Recording 2026-11-05 at 09.52.11 PM.mp4", "timestamp": 10}]},
           {"title": "Tap \"Comparar\" Button", "startTime": 11,
            "attachments": [{"name": "Synthesized Event 2026-11-05 at 09.52.17 PM_0_6D546067-CC4E-4BBC-9CCE-6BB2198D5680.jpeg", "timestamp": 11.5}]},
           {"title": "Added attachment named 'comparar produtos'", "startTime": 12,
            "attachments": [{"name": "comparar produtos_0_7D546067-CC4E-4BBC-9CCE-6BB2198D5680.png", "timestamp": 12}]},
           {"title": "Waiting for snapshot", "startTime": 13,
            "attachments": [{"name": "UI Snapshot 2026-11-05 at 09.52.24 PM_0_8D546067-CC4E-4BBC-9CCE-6BB2198D5680.jpeg", "timestamp": 13}]},
           {"title": "Failure", "startTime": 14, "attachments": [
             {"name": "Complete Issue Description.txt", "timestamp": 14},
             {"name": "App UI hierarchy for br.com.mbadmin.txt", "timestamp": 14}]}
         ]}]}
        """#
        let screenshots = XcresultTimeline.screenshots(in: Data(json.utf8))
        #expect(screenshots.map(\.name) == ["comparar produtos"])
        #expect(screenshots.first?.readySince == 11, "The tap is the step before it")
    }

    @Test(arguments: ["", "{}", "[1, 2]", #"{"testNodes": "none"}"#])
    func somethingElseGivesNothing(_ json: String) {
        #expect(XcresultTimeline.testIDs(in: Data(json.utf8)).isEmpty)
        #expect(XcresultTimeline.screenshots(in: Data(json.utf8)).isEmpty)
    }
}
#endif
