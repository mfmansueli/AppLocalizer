//
//  DisplayRecordingToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `start_display_recording` and `finish_display_recording`: a UI test's
/// screenshot on iPhone Duo is its cover display, so AppLocalizer opens the
/// Duo, records its inner display while the test runs, and gives each of
/// the test's screenshots back as the inner display then, uploaded for
/// `report_capture`. The helper's answers are canned: a booted Duo
/// (`DebugSimulators`) and a recording of the Streak sheet
/// (`RecordingTestFixtures`).
@MainActor
@Suite("Display recording tools")
struct DisplayRecordingToolsTests {
    private static let helper = URL(filePath: "/tmp/Start Claude Code.zsh")
    private static let start: [String: JSONValue] = ["run": "run-1", "displayType": "iphone_duo"]
    private static let finish: [String: JSONValue] = ["run": "run-1", "resultBundle": .string(RecordingTestFixtures.bundle)]

    private static var fixtures: MCPAutopilotFixtures {
        var plan = AutopilotTestFixtures.smallPlan
        plan.displayTypes = [.iPhone, .iPhoneDuo]
        return MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture, plan: plan))
    }

    private static func runner(shots: [DuoInnerDisplay] = [.showing]) -> FakeUnixScriptRunner {
        let runner = FakeUnixScriptRunner()
        runner.answers = [
            "simulators": [[DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: true, hasDuo: true, duoIsBooted: true))]],
            "simulator-displays": [DebugSimulators.displayLines],
            "simulator-screenshot": shots.map { [DebugSimulators.png($0).base64EncodedString()] },
            "simulator-crashes": [[]],
            "open-duo": [["pressed"]],
            "accessibility": [["trusted"]],
            "record-display": [RecordingTestFixtures.recordingLines],
            "test-results": [[RecordingTestFixtures.testsJSON()], [RecordingTestFixtures.activitiesJSON()]],
            "recorded-frame": [[RecordingTestFixtures.png.base64EncodedString()]],
            "discard-recording": [[]],
        ]
        return runner
    }

    private static func simulators(_ runner: FakeUnixScriptRunner) -> MacSimulators {
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        simulators.duo.interval = .zero
        return simulators
    }

    @Test func anOpenDuoIsRecordedRightAway() async throws {
        let fixtures = Self.fixtures
        let runner = Self.runner()
        let simulators = Self.simulators(runner)
        let outcome = try await fixtures.call(StartDisplayRecordingTool(), Self.start, simulators: simulators)
        #expect(outcome.result["status"] == "recording")
        #expect(outcome.result["simulator"] == .string(RecordingTestFixtures.udid))
        #expect(outcome.result["next"]?.stringValue?.contains("-destination 'id=\(RecordingTestFixtures.udid)'") == true)
        #expect(simulators.recorder.isRecording)
        #expect(runner.recordedArguments.last == ["record-display", RecordingTestFixtures.udid, DebugSimulators.innerDisplayID])
        #expect(!runner.recordedArguments.contains { $0.first == "open-duo" })
    }

    /// A closed Duo is opened first, in the run's log.
    @Test func aClosedDuoIsOpenedFirst() async throws {
        let fixtures = Self.fixtures
        let runner = Self.runner(shots: [.black, .showing])
        let simulators = Self.simulators(runner)
        let outcome = try await fixtures.call(StartDisplayRecordingTool(), Self.start, simulators: simulators)
        #expect(outcome.result["status"] == "recording")
        #expect(runner.recordedArguments.contains(["open-duo", RecordingTestFixtures.udid, "iPhone Duo"]))
        let log = fixtures.run?.log.map(\.text) ?? []
        #expect(log.contains(DuoWatcher.Event.pressedOpen.logText))
    }

    /// AppLocalizer can't open it without Accessibility: the assistant
    /// reports the Duo, and its card shows the person what to do.
    @Test func aDuoAppLocalizerCantOpenIsReported() async throws {
        let fixtures = Self.fixtures
        let runner = Self.runner(shots: [.black])
        runner.answers["open-duo"] = [["accessibility-needed"]]
        runner.statuses["open-duo"] = 77
        runner.answers["accessibility"] = [["not-trusted"]]
        let simulators = Self.simulators(runner)
        let outcome = try await fixtures.call(StartDisplayRecordingTool(), Self.start, simulators: simulators)
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["duo"] == .string(DuoState.needsAccessibility.summary))
        #expect(outcome.result["reason"]?.stringValue?.contains("report_capture_problem (displayType iphone_duo, affectsDevice true)") == true)
        #expect(!simulators.recorder.isRecording)
    }

    @Test func withoutTheHelperItSaysSo() async throws {
        let outcome = try await Self.fixtures.call(StartDisplayRecordingTool(), Self.start)
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.hasPrefix("AppLocalizer’s helper isn’t installed") == true)
    }

    @Test func onlyIPhoneDuoIsRecorded() async throws {
        let simulators = Self.simulators(Self.runner())
        await #expect(throws: MCPToolError.invalidArgument(
            name: "displayType", expected: "iphone_duo: on the other devices the UI test’s own screenshot is the whole screen"
        )) {
            try await Self.fixtures.call(StartDisplayRecordingTool(), ["run": "run-1", "displayType": "iphone"], simulators: simulators)
        }
        let withoutDuo = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture))
        await #expect(throws: MCPToolError.notFound("The plan doesn’t capture iPhone Duo.")) {
            try await withoutDuo.call(StartDisplayRecordingTool(), Self.start, simulators: simulators)
        }
    }

    /// The test's screenshot comes back as the inner display just before
    /// it, uploaded, with a small image to check; report_capture takes it.
    @Test func eachScreenshotComesBackAsAnUploadReportCaptureTakes() async throws {
        let fixtures = Self.fixtures
        let simulators = Self.simulators(Self.runner())
        _ = try await fixtures.call(StartDisplayRecordingTool(), Self.start, simulators: simulators)
        let outcome = try await fixtures.call(FinishDisplayRecordingTool(), Self.finish, simulators: simulators)

        let shot = try #require(outcome.result["screenshots"]?.arrayValue?.first)
        #expect(outcome.result["screenshots"]?.arrayValue?.count == 1)
        #expect(shot["name"] == "streak")
        #expect(shot["test"] == .string(RecordingTestFixtures.test))
        #expect(shot["size"] == "2853 × 2007")
        #expect(shot["takenBefore"] == "0.1 s before the test’s screenshot")
        #expect(shot["check"] == nil)
        #expect(outcome.images.map(\.mimeType) == ["image/jpeg"])
        #expect(fixtures.run?.log.last?.text == "iPhone Duo: streak taken from its inner display, recorded during the UI test")
        #expect(!simulators.recorder.isRecording)

        let upload = try #require(shot["upload"]?.stringValue)
        let report = try await fixtures.call(ReportCaptureTool(), [
            "run": "run-1", "screen": "today", "displayType": "iphone_duo", "locale": "en-US", "upload": .string(upload),
            "attempt": 1, "score": .double(0.9), "notes": "The Today screen on the inner display",
        ])
        #expect(report.result["status"] == "received")
        #expect(fixtures.run?.captures.last?.pixelSize == PixelSize(width: 2853, height: 2007))
    }

    /// A black frame: the Duo closed during the test.
    @Test func aBlackFrameSaysTheDuoClosed() async throws {
        let fixtures = Self.fixtures
        let runner = Self.runner()
        runner.answers["recorded-frame"] = [[DebugSimulators.png(.black, width: 2853, height: 2007).base64EncodedString()]]
        let simulators = Self.simulators(runner)
        _ = try await fixtures.call(StartDisplayRecordingTool(), Self.start, simulators: simulators)
        let outcome = try await fixtures.call(FinishDisplayRecordingTool(), Self.finish, simulators: simulators)
        let check = outcome.result["screenshots"]?.arrayValue?.first?["check"]?.stringValue
        #expect(check?.hasPrefix("The inner display is black: iPhone Duo closed.") == true)
    }

    @Test func finishingNeedsARecordingAndAnAbsoluteBundle() async throws {
        let fixtures = Self.fixtures
        let simulators = Self.simulators(Self.runner())
        let outcome = try await fixtures.call(FinishDisplayRecordingTool(), Self.finish, simulators: simulators)
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"] == .string(DisplayRecorder.Failure.notRecording.localizedDescription))
        await #expect(throws: MCPToolError.invalidArgument(name: "resultBundle", expected: "the absolute path of a .xcresult bundle")) {
            try await fixtures.call(FinishDisplayRecordingTool(), ["run": "run-1", "resultBundle": "build/streak.xcresult"], simulators: simulators)
        }
    }
}
#endif
