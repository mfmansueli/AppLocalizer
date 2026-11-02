//
//  DisplayRecorderTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// AppLocalizer recording iPhone Duo's inner display through the helper
/// while a UI test runs, then keeping the frame from just before each of
/// the test's screenshots, and deleting the rest. The helper's answers are
/// canned (`RecordingTestFixtures`).
@MainActor
@Suite("Display recorder")
struct DisplayRecorderTests {
    private static let helper = URL(filePath: "/tmp/Start Claude Code.zsh")
    private static let display = DebugSimulators.innerDisplayID
    private static let usage = "Usage: Start Claude Code.zsh check | run <folder> -- <claude arguments…> | simulators | …"

    private static func runner(device: String = RecordingTestFixtures.udid) -> FakeUnixScriptRunner {
        let runner = FakeUnixScriptRunner()
        runner.answers = [
            "record-display": [RecordingTestFixtures.recordingLines],
            "test-results": [[RecordingTestFixtures.testsJSON()], [RecordingTestFixtures.activitiesJSON(device: device)]],
            "recorded-frame": [[RecordingTestFixtures.png.base64EncodedString()]],
            "discard-recording": [[]],
        ]
        return runner
    }

    @Test func theFrameFromJustBeforeEachScreenshotIsKept() async throws {
        let runner = Self.runner()
        let simulators = MacSimulators(runner: runner, helperURL: Self.helper)
        let recorder = simulators.recorder
        #expect(!recorder.isRecording)
        try await recorder.start(udid: RecordingTestFixtures.udid, display: Self.display)
        #expect(recorder.isRecording)
        #expect(recorder.udid == RecordingTestFixtures.udid)

        let shots = try await recorder.finish(resultBundle: RecordingTestFixtures.bundle)
        let shot = try #require(shots.first)
        #expect(shots.count == 1)
        #expect(shot.pick.screenshot.name == "streak")
        #expect(shot.pick.frame == RecordingTestFixtures.frames[2])
        #expect(shot.png == RecordingTestFixtures.png)
        #expect(!shot.isOnOtherSimulator)
        #expect(!recorder.isRecording)
        #expect(runner.recordedArguments == [
            ["record-display", RecordingTestFixtures.udid, Self.display],
            ["test-results", RecordingTestFixtures.bundle],
            ["test-results", RecordingTestFixtures.bundle, RecordingTestFixtures.test],
            ["recorded-frame", RecordingTestFixtures.folder + "/" + RecordingTestFixtures.frames[2].file],
            ["discard-recording", RecordingTestFixtures.folder],
        ])
    }

    /// A test run on another simulator than the one recorded gets no frame.
    @Test func aTestOnAnotherSimulatorGetsNoFrame() async throws {
        let runner = Self.runner(device: "11111111-2222-3333-4444-555555555555")
        let simulators = MacSimulators(runner: runner, helperURL: Self.helper)
        try await simulators.recorder.start(udid: RecordingTestFixtures.udid, display: Self.display)
        let shots = try await simulators.recorder.finish(resultBundle: RecordingTestFixtures.bundle)
        #expect(shots.map(\.isOnOtherSimulator) == [true])
        #expect(shots.first?.png == nil)
        #expect(!runner.recordedArguments.contains { $0.first == "recorded-frame" })
    }

    /// A display that stops answering before the first frame: why, and
    /// nothing left recording.
    @Test func aRecordingWithoutFramesSaysWhy() async {
        let runner = Self.runner()
        runner.answers["record-display"] = [["folder \(RecordingTestFixtures.folder)"]]
        runner.statuses["record-display"] = 69
        runner.errorOutput = "The simulator's display stopped answering."
        let simulators = MacSimulators(runner: runner, helperURL: Self.helper)
        await #expect(throws: DisplayRecorder.Failure.didntStart("The simulator's display stopped answering.")) {
            try await simulators.recorder.start(udid: RecordingTestFixtures.udid, display: Self.display)
        }
        #expect(!simulators.recorder.isRecording)
        #expect(runner.recordedArguments.last == ["discard-recording", RecordingTestFixtures.folder])
    }

    @Test func anOlderHelperIsToldApart() async {
        let runner = Self.runner()
        runner.answers["record-display"] = nil
        runner.losesExitLine = true
        runner.errorOutput = Self.usage
        let simulators = MacSimulators(runner: runner, helperURL: Self.helper)
        await #expect(throws: DisplayRecorder.Failure.olderHelper) {
            try await simulators.recorder.start(udid: RecordingTestFixtures.udid, display: Self.display)
        }
    }

    @Test func finishingWithoutRecordingIsRefused() async {
        let simulators = MacSimulators(runner: Self.runner(), helperURL: Self.helper)
        await #expect(throws: DisplayRecorder.Failure.notRecording) {
            try await simulators.recorder.finish(resultBundle: RecordingTestFixtures.bundle)
        }
    }

    /// A bundle the helper can't read: why, and the recording is deleted.
    @Test func anUnreadableBundleSaysWhyAndDeletesTheRecording() async throws {
        let runner = Self.runner()
        runner.statuses["test-results"] = 64
        runner.errorOutput = "Usage: test-results <bundle.xcresult> [<test>]"
        let simulators = MacSimulators(runner: runner, helperURL: Self.helper)
        try await simulators.recorder.start(udid: RecordingTestFixtures.udid, display: Self.display)
        await #expect(throws: DisplayRecorder.Failure.unreadableResults("Usage: test-results <bundle.xcresult> [<test>]")) {
            try await simulators.recorder.finish(resultBundle: "/Users/sam/missing.xcresult")
        }
        #expect(runner.recordedArguments.last == ["discard-recording", RecordingTestFixtures.folder])
    }

    /// One recording at a time: starting again deletes the one before.
    @Test func aNewRecordingDeletesTheOneBefore() async throws {
        let runner = Self.runner()
        let simulators = MacSimulators(runner: runner, helperURL: Self.helper)
        try await simulators.recorder.start(udid: RecordingTestFixtures.udid, display: Self.display)
        try await simulators.recorder.start(udid: RecordingTestFixtures.udid, display: Self.display)
        #expect(runner.recordedArguments.map(\.first) == ["record-display", "discard-recording", "record-display"])
        #expect(simulators.recorder.isRecording)
    }
}
#endif
