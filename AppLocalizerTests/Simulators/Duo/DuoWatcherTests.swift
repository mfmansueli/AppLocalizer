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
/// stuck Duo, starts one that isn't running and opens a closed one during a
/// run (asking for Accessibility once when it needs it), and says when it's
/// open. The helper's answers are canned: a booted Duo on iOS 27.2
/// (`DebugSimulators`).
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
            "open-duo": [["pressed"]],
            "accessibility": [["trusted"]],
        ]
        return runner
    }

    private static let openDuo = ["open-duo", udid, "iPhone Duo"]

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

    /// While the plan is looked at, a closed Duo is only looked at, and
    /// the helper says whether AppLocalizer may open it when the run needs it.
    @Test func whileOnlyLookingAClosedDuoIsLeftClosed() async {
        let runner = Self.runner()
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(duo.state == .unknown)
        #expect(await duo.look(mayStart: false) == nil)
        #expect(duo.state == .closed)
        #expect(runner.recordedArguments == [
            ["simulators"],
            ["simulator-displays", Self.udid],
            ["simulator-screenshot", Self.udid, DebugSimulators.innerDisplayID],
            ["simulator-crashes", Self.udid],
            ["accessibility"],
        ])
        await duo.look(mayStart: false)
        #expect(Self.calls("simulator-displays", in: runner) == 1, "The inner display's ID holds until it starts again")
        #expect(Self.calls("accessibility", in: runner) == 1, "Once allowed, it isn't asked again")
        #expect(Self.calls("boot-simulator", in: runner) == 0)
        #expect(Self.calls("open-duo", in: runner) == 0)
        #expect(duo.state.summary == "Closed: AppLocalizer opens it in Device Hub.")
    }

    /// During a run AppLocalizer opens it: the helper presses Open in Device
    /// Hub, and the next look sees it open.
    @Test func duringARunAClosedDuoIsOpened() async {
        let runner = Self.runner(shots: [.black, .showing])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == .pressedOpen)
        #expect(duo.state == .opening)
        #expect(duo.state.isWorking)
        #expect(runner.recordedArguments.last == Self.openDuo)
        #expect(await duo.look(mayStart: true) == .opened)
        #expect(duo.state == .open)
        #expect(await duo.look(mayStart: true) == nil)
        #expect(Self.calls("open-duo", in: runner) == 1)
        #expect(DuoWatcher.Event.pressedOpen.logText == "iPhone Duo was closed: AppLocalizer opened it in Device Hub")
    }

    @Test func onceItsOpenedItSaysSoOnce() async {
        let runner = Self.runner(shots: [.black, .showing])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: false) == nil)
        #expect(await duo.look(mayStart: false) == .opened)
        #expect(duo.state == .open)
        #expect(await duo.look(mayStart: false) == nil)
        #expect(Self.calls("simulator-crashes", in: runner) == 1, "An open Duo's crashes don't matter")
    }

    /// Without Accessibility the helper can't press Open: macOS asks the
    /// person once, and later looks try again, so it opens once allowed.
    @Test func withoutAccessibilityMacOSAsksOnceAndItOpensOnceAllowed() async {
        let runner = Self.runner(shots: [.black, .black, .black, .showing])
        runner.answers["open-duo"] = [["accessibility-needed"], ["accessibility-needed"], ["pressed"]]
        runner.statuses["open-duo"] = 77
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == .askedForAccessibility)
        #expect(duo.state == .needsAccessibility)
        #expect(runner.recordedArguments.last == ["accessibility", "prompt"])
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .needsAccessibility)
        #expect(Self.calls("accessibility", in: runner) == 1, "macOS asks once")
        #expect(duo.state.waitsForPerson)
        #expect(duo.state.summary.contains("allow AppLocalizer in Privacy & Security › Accessibility"))

        runner.statuses["open-duo"] = nil
        #expect(await duo.look(mayStart: true) == .pressedOpen)
        #expect(await duo.look(mayStart: true) == .opened)
        #expect(Self.calls("open-duo", in: runner) == 3)
    }

    /// The plan says so before Start, and notices once it's allowed.
    @Test func whileOnlyLookingItSaysWhetherAppLocalizerMayOpenIt() async {
        let runner = Self.runner()
        runner.answers["accessibility"] = [["not-trusted"], ["trusted"]]
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        await duo.look(mayStart: false)
        #expect(duo.state == .needsAccessibility)
        await duo.look(mayStart: false)
        #expect(duo.state == .closed)
        await duo.look(mayStart: false)
        #expect(Self.calls("accessibility", in: runner) == 2)
        #expect(!runner.recordedArguments.contains(["accessibility", "prompt"]), "Only a run's try has macOS ask")
    }

    @Test func aDuoThatDoesntOpenIsLeftToThePersonAfterTwoTries() async {
        let runner = Self.runner()
        runner.answers["open-duo"] = [["no-open-button"]]
        runner.statuses["open-duo"] = 69
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .closed)
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .couldntOpen("Device Hub didn’t show its Open pose"))
        await duo.look(mayStart: true)
        #expect(Self.calls("open-duo", in: runner) == DuoStep.maximumOpens)
        #expect(duo.state.waitsForPerson)
        #expect(duo.state.summary == "Closed: AppLocalizer couldn’t open it (Device Hub didn’t show its Open pose). Open it in Device Hub.")
    }

    /// Open pressed, and still black: tried once more, then left to the
    /// person.
    @Test func pressingOpenThatDoesntOpenItIsTriedTwice() async {
        let runner = Self.runner()
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == .pressedOpen)
        #expect(await duo.look(mayStart: true) == .pressedOpen)
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .couldntOpen("Device Hub didn’t open it"))
        #expect(Self.calls("open-duo", in: runner) == 2)
    }

    /// A helper from before it could open the Duo (version 4) still looks
    /// and restarts it; the card asks to save it again.
    @Test func aHelperThatCantOpenItAsksToBeSavedAgain() async {
        let runner = Self.runner()
        runner.answers["open-duo"] = nil
        runner.answers["accessibility"] = nil
        runner.losesExitLine = true
        runner.errorOutput = "Usage: Start Claude Code.zsh check | run <folder> -- <claude arguments…> | simulators | …"
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true) == nil)
        #expect(duo.state == .helperCantOpen)
        await duo.look(mayStart: true)
        #expect(duo.state == .helperCantOpen)
        #expect(duo.state.isWatched)
        #expect(Self.calls("open-duo", in: runner) == 1)
        #expect(duo.state.summary.hasPrefix("Closed: save the helper again so AppLocalizer can open it itself"))
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

    @Test func aDuoThatIsntRunningIsStartedAndOpenedOnlyDuringARun() async {
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
        #expect(await duo.look(mayStart: true) == .pressedOpen, "It starts closed")
    }

    /// Watching tells each event as it comes, and goes on until it's
    /// cancelled.
    @Test func watchingTellsEachEventUntilItsCancelled() async {
        let simulators = Self.simulators(Self.runner(shots: [.black, .black, .showing]))
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        // Its own task: cancelling the test's would skip it.
        let watching = Task { @MainActor in
            var events: [DuoWatcher.Event] = []
            await duo.watch(mayStart: true) { event in
                events.append(event)
                if event == .opened { withUnsafeCurrentTask { $0?.cancel() } }
            }
            return events
        }
        #expect(await watching.value == [.pressedOpen, .pressedOpen, .opened])
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
