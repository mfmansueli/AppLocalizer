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

    @Test(arguments: ["", "{}", "[1, 2]", #"{"testNodes": "none"}"#])
    func somethingElseGivesNothing(_ json: String) {
        #expect(XcresultTimeline.testIDs(in: Data(json.utf8)).isEmpty)
        #expect(XcresultTimeline.screenshots(in: Data(json.utf8)).isEmpty)
    }
}
#endif
