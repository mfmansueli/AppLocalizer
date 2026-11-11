//
//  SimulatorRepairTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// AppLocalizer putting this Mac's simulators right through the helper.
@MainActor
@Suite("SimulatorRepair")
struct SimulatorRepairTests {
    private let helper = URL(filePath: "/tmp/Start Claude Code.zsh")
    private let udid = "5A1B2C3D-0000-4000-8000-ABCDEF012345"
    private static let audioError = "Bundle com.apple.CoreSimulator.SimAudioProcessorServices failed to create an audio route descriptor"

    private func make(_ configure: (FakeUnixScriptRunner) -> Void) -> (MacSimulators, FakeUnixScriptRunner) {
        let runner = FakeUnixScriptRunner()
        runner.answers = ["repair-simulators": [[]], "repair-audio": [[]], "boot-simulator": [["Device already booted, nothing to do."]]]
        configure(runner)
        return (MacSimulators(runner: runner, helperURL: helper), runner)
    }

    @Test func theAudioServiceIsRestartedThenASimulatorStarted() async {
        let (simulators, runner) = make { _ in }
        let outcome = await simulators.repair.repair(.audioService, probe: udid)
        #expect(outcome == .repaired)
        #expect(simulators.repair.state == .repaired)
        #expect(runner.recordedArguments == [["repair-audio"], ["boot-simulator", udid]])
    }

    @Test func aStuckSimulatorServiceNeedsNoPassword() async {
        let (simulators, runner) = make { _ in }
        #expect(await simulators.repair.repair(.simulatorService, probe: udid) == .repaired)
        #expect(runner.recordedArguments == [["repair-simulators"], ["boot-simulator", udid]])
    }

    /// Restarting the simulators shows it was the audio service all along.
    @Test func aServiceRestartThatStillFailsOverAudioGoesOnToTheAudioService() async {
        let (simulators, runner) = make { runner in
            runner.answers["boot-simulator"] = [["An error was encountered processing the command:", Self.audioError], ["Booted"]]
            runner.statusSequences["boot-simulator"] = [5, 0]
        }
        #expect(await simulators.repair.repair(.simulatorService, probe: udid) == .repaired)
        #expect(runner.recordedArguments.map(\.first) == ["repair-simulators", "boot-simulator", "repair-audio", "boot-simulator"])
    }

    @Test func aStartThatStillFailsSaysWhatSimctlSaid() async {
        let (simulators, _) = make { runner in
            runner.answers["boot-simulator"] = [["Unable to boot device in current state: Creating"]]
            runner.statuses["boot-simulator"] = 149
        }
        let outcome = await simulators.repair.repair(.simulatorService, probe: udid)
        #expect(outcome == .failed("Unable to boot device in current state: Creating"))
        #expect(outcome.message?.contains("Restarting the Mac usually fixes it.") == true)
    }

    @Test func aClosedPasswordRequestIsNotAFailure() async {
        let (simulators, runner) = make { $0.statuses["repair-audio"] = SimulatorRepair.declinedStatus }
        #expect(await simulators.repair.repair(.audioService, probe: udid) == .declined)
        #expect(runner.recordedArguments == [["repair-audio"]], "Nothing to check: nothing was restarted")
    }

    @Test func aHelperFromBeforeIsToBeSavedAgain() async {
        let runner = FakeUnixScriptRunner()
        runner.exitStatus = 64
        runner.losesExitLine = true
        runner.errorOutput = "Usage: Start Claude Code.zsh check | run <folder> -- <claude arguments…>"
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        #expect(await simulators.repair.repair(.audioService, probe: udid) == .needsHelper)
        #expect(await simulators.repair.repair(.simulatorService, probe: udid) == .needsHelper)
    }

    @Test func withoutTheHelperNothingRuns() async {
        let (simulators, runner) = make { $0.helperExists = false }
        #expect(await simulators.repair.repair(.audioService, probe: udid) == .needsHelper)
        #expect(runner.recordedArguments.isEmpty)
    }

    @Test func withoutASimulatorToStartTheRestartIsTakenAsDone() async {
        let (simulators, runner) = make { _ in }
        #expect(await simulators.repair.repair(.audioService, probe: nil) == .repaired)
        #expect(runner.recordedArguments == [["repair-audio"]])
    }

    @Test func itTriesOnItsOwnOncePerProblem() {
        let (simulators, _) = make { _ in }
        let repair = simulators.repair
        #expect(repair.shouldTryOnItsOwn(for: ["pr-1", "pr-2"]))
        #expect(!repair.shouldTryOnItsOwn(for: ["pr-1", "pr-2"]))
        #expect(!repair.shouldTryOnItsOwn(for: ["pr-2"]))
        #expect(repair.shouldTryOnItsOwn(for: ["pr-2", "pr-3"]), "A new problem is a new try")
    }

    @Test func everyStateButIdleSaysSomething() {
        let states: [SimulatorRepairState] = [
            .restartingSimulators, .restartingAudio, .checking, .repaired, .declined, .needsHelper, .failed("It didn’t start."),
        ]
        #expect(SimulatorRepairState.idle.message == nil)
        for state in states {
            #expect(state.message?.isEmpty == false)
        }
        #expect(states.filter(\.isWorking) == [.restartingSimulators, .restartingAudio, .checking])
    }
}
#endif
