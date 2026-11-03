//
//  DuoClosedScreensTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// iPhone Duo's closed screenshots come first: while they're left, the
/// watcher keeps the Duo closed (it never opens it) and closes an open one
/// by restarting it; once only open ones are left, it opens it.
@MainActor
@Suite("iPhone Duo kept closed for its closed screenshots")
struct DuoClosedScreensTests {
    private static let helper = URL(filePath: "/tmp/Start Claude Code.zsh")
    private static let udid = "00000000-0000-0000-0000-000000000004"
    private let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private static func runner(shots: [DuoInnerDisplay]) -> FakeUnixScriptRunner {
        let runner = FakeUnixScriptRunner()
        runner.answers = [
            "simulators": [[DebugSimulators.json(DebugSimulators.Mac(hasNewRuntime: true, hasDuo: true, duoIsBooted: true))]],
            "simulator-displays": [DebugSimulators.displayLines],
            "simulator-screenshot": shots.map { [DebugSimulators.png($0).base64EncodedString()] },
            "simulator-crashes": [[]],
            "boot-simulator": [["Monitoring boot status for iPhone Duo (\(udid))."]],
            "shutdown-simulator": [[]],
            "open-duo": [["pressed"]],
            "accessibility": [["trusted"]],
        ]
        return runner
    }

    private static func simulators(_ runner: FakeUnixScriptRunner) -> MacSimulators {
        let simulators = MacSimulators(runner: runner, helperURL: helper)
        simulators.duo.interval = .zero
        return simulators
    }

    // MARK: - Steps

    @Test func anOpenDuoIsClosedWhileClosedScreenshotsAreLeft() {
        let open = DuoStep.Look(isBooted: true, inner: .showing)
        #expect(DuoStep.next(after: open, restarts: 0, mayStart: true, wants: .closed, now: now) == .close)
        #expect(DuoStep.next(after: open, restarts: 0, closes: DuoStep.maximumCloses, mayStart: true, wants: .closed, now: now) == .wait)
        #expect(DuoStep.next(after: open, restarts: 0, mayStart: false, wants: .closed, now: now) == .wait, "Only during a run")
        #expect(DuoStep.next(after: open, restarts: 0, mayStart: true, wants: .open, now: now) == .wait)
    }

    @Test func aClosedDuoIsOpenedOnlyForOpenScreenshots() {
        let closed = DuoStep.Look(isBooted: true, inner: .black)
        #expect(DuoStep.next(after: closed, restarts: 0, mayStart: true, wants: .closed, now: now) == .wait)
        #expect(DuoStep.next(after: closed, restarts: 0, mayStart: true, wants: nil, now: now) == .wait, "Nothing to capture on it now")
        #expect(DuoStep.next(after: closed, restarts: 0, mayStart: true, wants: .open, now: now) == .open)
        #expect(DuoStep.next(after: DuoStep.Look(isBooted: false), restarts: 0, mayStart: true, wants: .closed, now: now) == .start)
    }

    // MARK: - Watching

    @Test func aClosedDuoStaysClosedForItsClosedScreenshots() async {
        let runner = Self.runner(shots: [.black])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        #expect(await simulators.duo.look(mayStart: true, wants: .closed) == nil)
        #expect(simulators.duo.state == .closedForScreens)
        #expect(!runner.recordedArguments.contains { $0.first == "open-duo" })
    }

    @Test func anOpenDuoIsRestartedWhichClosesIt() async {
        let runner = Self.runner(shots: [.showing, .black])
        let simulators = Self.simulators(runner)
        defer { withExtendedLifetime(simulators) {} }
        let duo = simulators.duo
        #expect(await duo.look(mayStart: true, wants: .closed) == .closed)
        #expect(duo.state == .closedForScreens)
        #expect(runner.recordedArguments.contains(["shutdown-simulator", Self.udid]))
        #expect(runner.recordedArguments.contains(["boot-simulator", Self.udid]))
        #expect(DuoWatcher.Event.closed.logText
            == "iPhone Duo was open and its closed screenshots are next: AppLocalizer restarted it, which closes it")

        // Then only open ones are left: it's opened.
        #expect(await duo.look(mayStart: true, wants: .open) == .pressedOpen)
    }
}
#endif
