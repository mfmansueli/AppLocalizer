//
//  NextStepDuoPoseTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `next_step` folds iPhone Duo before it gives the closed screens: Alba's
/// run started with the Duo left open, the watcher in the Making step
/// didn't close it in time, and all four cover screenshots were black.
/// The helper's answers are canned: a booted Duo (`DebugSimulators`).
@MainActor
@Suite("next_step folds iPhone Duo")
struct NextStepDuoPoseTests {
    private static let helper = URL(filePath: "/tmp/Start Claude Code.zsh")
    private static let udid = "00000000-0000-0000-0000-000000000004"

    /// A run that hasn't captured iPhone Duo's closed screens yet.
    private static var closedFirstRun: AutopilotRun {
        var plan = AutopilotTestFixtures.smallPlan
        plan.displayTypes = [.iPhone, .iPhoneDuo]
        plan.runChoice.duoScreens = .both
        plan.runChoice.duoBoth = .sideBySide
        return AutopilotTestFixtures.run(.capture, plan: plan)
    }

    private static func runner(shots: [DuoInnerDisplay]) -> FakeUnixScriptRunner {
        let runner = FakeUnixScriptRunner()
        runner.answers = [
            "simulators": [[DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: true, hasDuo: true, duoIsBooted: true))]],
            "simulator-displays": [DebugSimulators.displayLines],
            "simulator-screenshot": shots.map { [DebugSimulators.png($0).base64EncodedString()] },
            "simulator-crashes": [[]],
            "boot-simulator": [["Monitoring boot status for iPhone Duo (\(udid))."]],
            "shutdown-simulator": [[]],
            "accessibility": [["trusted"]],
        ]
        return runner
    }

    private static func simulators(_ runner: FakeUnixScriptRunner) -> MacSimulators {
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        simulators.duo.interval = .zero
        return simulators
    }

    private static func restarted(_ runner: FakeUnixScriptRunner) -> Bool {
        runner.recordedArguments.contains(["shutdown-simulator", udid]) && runner.recordedArguments.contains(["boot-simulator", udid])
    }

    @Test func anOpenDuoIsFoldedBeforeItsClosedScreens() async throws {
        let fixtures = MCPAutopilotFixtures(Self.closedFirstRun)
        let runner = Self.runner(shots: [.showing, .black])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let outcome = try await fixtures.call(NextStepTool(), ["run": "run-1"], simulators: simulators)
        #expect(outcome.result["action"] == "capture")
        #expect(Self.restarted(runner))
        #expect(outcome.result["iPhoneDuo"]?.stringValue?.hasPrefix("iPhone Duo is folded: capture its closed targets now") == true)
        #expect(fixtures.run?.log.map(\.text).contains(DuoWatcher.Event.closed.logText) == true)
    }

    @Test func aFoldedDuoIsLeftAsItIs() async throws {
        let fixtures = MCPAutopilotFixtures(Self.closedFirstRun)
        let runner = Self.runner(shots: [.black])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let outcome = try await fixtures.call(NextStepTool(), ["run": "run-1"], simulators: simulators)
        #expect(!Self.restarted(runner))
        #expect(outcome.result["iPhoneDuo"]?.stringValue?.hasPrefix("iPhone Duo is folded") == true)
    }

    /// Past the closed screens, opening it is `start_display_recording`'s.
    @Test func onlyOpenScreensLeftItIsntLookedAt() async throws {
        var run = Self.closedFirstRun
        let closed = run.plan.targets.filter { run.plan.duoPose(for: $0) == .closed }
        AutopilotTestFixtures.captureAll(&run, except: Set(run.plan.targets).subtracting(closed))
        let fixtures = MCPAutopilotFixtures(run)
        let runner = Self.runner(shots: [.black])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let outcome = try await fixtures.call(NextStepTool(), ["run": "run-1"], simulators: simulators)
        #expect(outcome.result["iPhoneDuo"] == nil)
        #expect(!runner.recordedArguments.contains { $0.first == "simulator-screenshot" })
    }

    /// The assistant reported the open Duo before AppLocalizer folded it:
    /// that problem is tried again, as the watcher does.
    @Test func foldingItTriesTheDuoProblemAgain() async throws {
        let fixtures = MCPAutopilotFixtures(Self.closedFirstRun)
        let problem = try fixtures.center.reportProblem(
            appID: MCPAutopilotFixtures.appID, target: AutopilotTestFixtures.target("today", .iPhoneDuo, "en-US"),
            what: "iPhone Duo is open while the closed screenshots are due.", proposedFix: nil, affectsDevice: true
        )
        let runner = Self.runner(shots: [.showing, .black])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        _ = try await fixtures.call(NextStepTool(), ["run": "run-1"], simulators: simulators)
        let after = try #require(fixtures.run?.problems.first { $0.id == problem.id })
        #expect(after.resolution == .retryWithFix)
    }

    /// Restarted twice and still open: the assistant goes on with the rest
    /// and reports it, instead of capturing black cover screenshots.
    @Test func aDuoThatWontFoldIsSaidSo() async throws {
        let fixtures = MCPAutopilotFixtures(Self.closedFirstRun)
        let runner = Self.runner(shots: [.showing])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        var outcome = try await fixtures.call(NextStepTool(), ["run": "run-1"], simulators: simulators)
        outcome = try await fixtures.call(NextStepTool(), ["run": "run-1"], simulators: simulators)
        #expect(outcome.result["iPhoneDuo"]?.stringValue?.hasPrefix("iPhone Duo is folded") == true, "Restarted a second time")
        outcome = try await fixtures.call(NextStepTool(), ["run": "run-1"], simulators: simulators)
        let note = try #require(outcome.result["iPhoneDuo"]?.stringValue)
        #expect(note.hasPrefix("iPhone Duo isn't folded, and AppLocalizer can't fold it by itself now"))
        #expect(note.contains("report it once with report_capture_problem (displayType iphone_duo, affectsDevice true)"))
        #expect(runner.recordedArguments.count { $0.first == "shutdown-simulator" } == DuoStep.maximumCloses)
    }

    @Test func theGuidanceNoLongerSaysItStartsFolded() {
        var plan = Self.closedFirstRun.plan
        for both in [AutopilotDuoBoth.sideBySide, .separate] {
            plan.runChoice.duoBoth = both
            let rule = AutopilotRun.duoRule(plan)
            #expect(rule.contains("next_step folds the Duo before it gives them"))
            #expect(!rule.contains("starts folded"))
        }
    }
}
#endif
