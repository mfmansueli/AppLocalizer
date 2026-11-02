//
//  RecordedFramePickTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The frame kept for a test's screenshot: the last one captured before
/// the test took it, settled when it started after the test's step before.
@Suite("Recorded frame picks")
struct RecordedFramePickTests {
    private static let screenshot = TestScreenshot(
        test: RecordingTestFixtures.test, name: "streak", time: RecordingTestFixtures.attachedAt,
        readySince: RecordingTestFixtures.readySince, deviceID: RecordingTestFixtures.udid
    )

    @Test func theLastFrameCapturedBeforeTheScreenshotIsKept() throws {
        let pick = try #require(RecordedFramePick.picks(for: [Self.screenshot], in: RecordingTestFixtures.frames.reversed()).first)
        #expect(pick.frame == RecordingTestFixtures.frames[2], "Not the one whose capture ended after the screenshot")
        #expect(abs((pick.lead ?? 0) - 0.116) < 0.001)
        #expect(pick.isSettled)
    }

    /// A test that takes its screenshot as soon as the screen appears: the
    /// frame may show the screen before.
    @Test func aFrameFromBeforeTheTestsStepIsntSettled() throws {
        let pick = try #require(RecordedFramePick.picks(for: [Self.screenshot], in: Array(RecordingTestFixtures.frames.prefix(2))).first)
        #expect(pick.frame == RecordingTestFixtures.frames[1])
        #expect(!pick.isSettled)
        var unknownStep = Self.screenshot
        unknownStep.readySince = nil
        #expect(RecordedFramePick.picks(for: [unknownStep], in: RecordingTestFixtures.frames).first?.isSettled == true)
    }

    @Test func aScreenshotBeforeEveryFrameHasNone() throws {
        var early = Self.screenshot
        early.time = 1_793_626_240.5
        let pick = try #require(RecordedFramePick.picks(for: [early], in: RecordingTestFixtures.frames).first)
        #expect(pick.frame == nil)
        #expect(pick.lead == nil)
        #expect(!pick.isSettled)
        #expect(RecordedFramePick.picks(for: [], in: RecordingTestFixtures.frames).isEmpty)
    }

    /// Several screenshots in one test run each get their own frame.
    @Test func eachScreenshotGetsItsOwnFrame() {
        var first = Self.screenshot
        first.name = "home"
        first.time = 1_793_626_242
        first.readySince = 1_793_626_240
        let picks = RecordedFramePick.picks(for: [first, Self.screenshot], in: RecordingTestFixtures.frames)
        #expect(picks.map(\.frame) == [RecordingTestFixtures.frames[0], RecordingTestFixtures.frames[2]])
    }
}
#endif
