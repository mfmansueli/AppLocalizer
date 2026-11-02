//
//  DuoWatcherTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// AppLocalizer watching iPhone Duo's simulator through the helper: it
/// finds the inner display, tells closed, stuck and open apart, restarts a
/// stuck Duo, starts one that isn't running during a run, and says when the
/// person has opened it. The helper's answers are canned: a booted Duo on
/// iOS 27.2 (`DebugSimulators`).
@MainActor
@Suite("iPhone Duo watcher")
struct DuoWatcherTests {
    private static let helper = URL(filePath: "/tmp/Start Claude Code.zsh")
    private static let udid = "00000000-0000-0000-0000-000000000004"
    private static let crash = "1730383600 SpringBoard-2026-11-02-105727.ips"

    private static func list(booted: Bool, duo: Bool = true) -> [String] {
        [DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: true, hasDuo: duo, duoIsBooted: booted))]
    }

    private static func runner(
        lists: [[String]] = [list(booted: true)], shots: [DuoInnerDisplay] = [.black], crashes: [[String]] = [[]]
    ) -> FakeUnixScriptRunner {
        let runner = FakeUnixScriptRunner()
        runner.answers = [
            "simulators": lists,
            "simulator-displays": [DebugSimulators.displayLines],
            "simulator-screenshot": shots.map { [DebugSimulators.png($0).base64EncodedString()] },
            "simulator-crashes": crashes,
            "boot-simulator": [["Monitoring boot status for iPhone Duo (\(udid))."]],
            "shutdown-simulator": [[]],
        ]
        return runner
    }

    /// The watcher holds its `MacSimulators` weakly (the launcher keeps it in
    /// the app), so each test keeps it till the end.
    private static func simulators(_ runner: FakeUnixScriptRunner) -> MacSimulators {
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        simulators.duo.interval = .zero
        return simulators
    }

    private static func calls(_ mode: String, in runner: FakeUnixScriptRunner) -> Int {
        runner.recordedArguments.count { $0.first == mode }
    }

    @Test func aClosedDuoIsLeftToThePerson() async {
        let runner = Self.runner()
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(duo.state == .unknown)
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .closed)
        #expect(runner.recordedArguments == [
            ["simulators"],
            ["simulator-displays", Self.udid],
            ["simulator-screenshot", Self.udid, DebugSimulators.innerDisplayID],
            ["simulator-crashes", Self.udid],
        ])
        await duo.look(mayStart: true)
        #expect(Self.calls("simulator-displays", in: runner) == 1, "The inner display's ID holds until it starts again")
        #expect(Self.calls("boot-simulator", in: runner) == 0)
    }

    @Test func onceThePersonOpensItItSaysSoOnce() async {
        let runner = Self.runner(shots: [.black, .showing])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == nil)
        #expect(await duo.look(mayStart: true) == .opened)
        #expect(duo.state == .open)
        #expect(await duo.look(mayStart: true) == nil)
        #expect(Self.calls("simulator-crashes", in: runner) == 1, "An open Duo's crashes don't matter")
    }

    /// Open when it first looks: whatever stopped the run there isn't the
    /// Duo being closed, so the run isn't told to try it again.
    @Test func aDuoOpenFromTheStartIsLeftAlone() async {
        let simulators = Self.simulators(Self.runner(shots: [.showing]))
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .open)
    }

    /// The real stuck Duo: SpringBoard crashed and only a spinner showed. A
    /// restart brings it back closed; crashes from before don't count, as
    /// the helper lists only those since it started.
    @Test func aStuckDuoIsRestartedAndComesBackClosed() async {
        let runner = Self.runner(shots: [.spinner, .black], crashes: [[Self.crash], []])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: false) == .restarted(.springBoardCrashed))
        #expect(duo.state == .closed)
        #expect(Array(runner.recordedArguments.suffix(3)) == [
            ["shutdown-simulator", Self.udid], ["boot-simulator", Self.udid], ["simulators"],
        ])
        #expect(await duo.look(mayStart: false) == nil)
        #expect(duo.state == .closed)
        #expect(Self.calls("simulator-displays", in: runner) == 2, "Its displays get new IDs when it starts")
        #expect(Self.calls("shutdown-simulator", in: runner) == 1)
    }

    /// Two looks at once (a view's task restarted while the first waited on
    /// the helper) restart a stuck Duo once.
    @Test func lookingTwiceAtOnceRestartsItOnce() async {
        let runner = Self.runner(shots: [.spinner, .black], crashes: [[Self.crash], []])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        async let first = duo.look(mayStart: true)
        async let second = duo.look(mayStart: true)
        let events = await [first, second].compactMap(\.self)
        #expect(events == [.restarted(.springBoardCrashed)])
        #expect(Self.calls("shutdown-simulator", in: runner) == 1)
    }

    @Test func aSpinnerThatLastsRestartsIt() async {
        let clock = Clock()
        let simulators = Self.simulators(Self.runner(shots: [.spinner]))
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        duo.now = { clock.date }
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .spinner)
        clock.date.addTimeInterval(30)
        #expect(await duo.look(mayStart: true) == nil, "Still starting, or being opened")
        clock.date.addTimeInterval(DuoStep.spinnerLimit)
        #expect(await duo.look(mayStart: true) == .restarted(.spinner))
    }

    @Test func stillStuckAfterTwoRestartsItsLeftToThePerson() async {
        let runner = Self.runner(shots: [.spinner], crashes: [[Self.crash]])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == .restarted(.springBoardCrashed))
        #expect(await duo.look(mayStart: true) == .restarted(.springBoardCrashed))
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .stuck(.springBoardCrashed))
        #expect(Self.calls("shutdown-simulator", in: runner) == DuoStep.maximumRestarts)
        #expect(duo.state.summary.contains("erase it in Device Hub"))
    }

    @Test func aDuoThatIsntRunningIsStartedOnlyDuringARun() async {
        let runner = Self.runner(lists: [Self.list(booted: false), Self.list(booted: true)])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: false) == nil)
        #expect(duo.state == .notRunning)
        #expect(Self.calls("boot-simulator", in: runner) == 0)

        #expect(await duo.look(mayStart: true) == .started)
        #expect(duo.state == .closed)
        #expect(runner.recordedArguments.contains(["boot-simulator", Self.udid]))
    }

    @Test func watchingEndsOnceItsOpened() async {
        let simulators = Self.simulators(Self.runner(shots: [.black, .black, .showing]))
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        var events: [DuoWatcher.Event] = []
        #expect(await duo.watch(mayStart: true, untilOpened: true) { events.append($0) })
        #expect(events == [.opened])
        #expect(DuoWatcher.Event.opened.logText == "iPhone Duo is open: its screens are captured next")
    }

    @Test func anOlderHelperAsksToBeSavedAgain() async {
        let runner = Self.runner()
        runner.answers["simulator-displays"] = nil
        runner.losesExitLine = true
        runner.exitStatus = 64
        runner.errorOutput = "Usage: Start Claude Code.zsh check | run <folder> -- <claude arguments…> | simulators | …"
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        await duo.look(mayStart: true)
        #expect(duo.state == .oldHelper)
        #expect(!duo.state.isWatched)
        #expect(duo.state.summary.hasPrefix("Save the helper again"))
    }

    @Test func withoutTheHelperOrTheSimulatorTheresNothingToWatch() async {
        let missing = Self.runner()
        missing.helperExists = false
        let noHelperSimulators = Self.simulators(missing)
        defer { withExtendedLifetime(noHelperSimulators) {} }
        let noHelper = noHelperSimulators.duo
        await noHelper.look(mayStart: true)
        #expect(noHelper.state == .noHelper)

        let noDuoSimulators = Self.simulators(Self.runner(lists: [Self.list(booted: false, duo: false)]))
        defer { withExtendedLifetime(noDuoSimulators) {} }
        let noDuo = noDuoSimulators.duo
        await noDuo.look(mayStart: true)
        #expect(noDuo.state == .noSimulator)
    }

    private final class Clock {
        var date = Date(timeIntervalSinceReferenceDate: 815_000_000)
    }
}
#endif
