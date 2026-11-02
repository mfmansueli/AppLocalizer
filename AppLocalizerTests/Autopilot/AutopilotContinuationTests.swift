//
//  AutopilotContinuationTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Keeping a run going: Claude Code started again when it stops with work
/// left and made progress, never in a loop, and a run nobody works on
/// saying so.
@MainActor
@Suite("Autopilot continuation")
struct AutopilotContinuationTests {
    private static let now = AutopilotTestFixtures.now

    /// Capturing, started by AppLocalizer, with nothing captured yet.
    private static func run(startsClaudeCode: Bool? = true) -> AutopilotRun {
        var run = AutopilotTestFixtures.run(.capture)
        run.startsClaudeCode = startsClaudeCode
        return run
    }

    private static func session(_ phase: ClaudeCodeRun.Phase, startedAt: Date = now, said: String? = nil) -> ClaudeCodeRun {
        var session = ClaudeCodeRun(
            id: UUID(), appID: AutopilotTestFixtures.appID, appName: "Lumen Journal", purpose: .autopilot, prompt: "Run…",
            workingDirectory: "/Users/sam/Developer/Lumen", startedAt: startedAt
        )
        session.phase = phase
        if let said { session.result = ClaudeCodeResult(isError: false, text: said, sessionID: nil) }
        return session
    }

    private static func captured(_ run: inout AutopilotRun, after seconds: TimeInterval) {
        run.captures.append(AutopilotTestFixtures.capture(AutopilotTestFixtures.target("today"), second: Int(seconds)))
    }

    // MARK: - Starting again

    @Test func aSessionThatSentSomethingIsStartedAgain() {
        var run = Self.run()
        Self.captured(&run, after: 120)
        #expect(AutopilotContinuation.shouldStartAgain(after: Self.session(.finished, startedAt: Self.now.addingTimeInterval(60)), run: run))
        let failed = Self.session(.failed(.notLoggedIn("Not logged in")), startedAt: Self.now)
        #expect(AutopilotContinuation.shouldStartAgain(after: failed, run: run), "A failure after progress too")
    }

    @Test func oneThatSentNothingIsntSoItCantLoop() {
        var run = Self.run()
        Self.captured(&run, after: 30)
        #expect(!AutopilotContinuation.shouldStartAgain(after: Self.session(.finished, startedAt: Self.now.addingTimeInterval(60)), run: run))
    }

    @Test func notAfterStopNorForAPastedRunNorWithNothingLeft() {
        var run = Self.run()
        Self.captured(&run, after: 120)
        #expect(!AutopilotContinuation.shouldStartAgain(after: Self.session(.stopped), run: run), "The person stopped it")
        #expect(!AutopilotContinuation.shouldStartAgain(after: Self.session(.working), run: run))

        var pasted = Self.run(startsClaudeCode: nil)
        Self.captured(&pasted, after: 120)
        #expect(!AutopilotContinuation.shouldStartAgain(after: Self.session(.finished), run: pasted))

        var waiting = Self.run()
        AutopilotTestFixtures.captureAll(&waiting, except: [AutopilotTestFixtures.target("week")])
        waiting.problems = [AutopilotTestFixtures.problem(AutopilotTestFixtures.target("week"))]
        #expect(!AutopilotContinuation.shouldStartAgain(after: Self.session(.finished), run: waiting), "It waits for the person")

        var old = Self.run()
        Self.captured(&old, after: 120)
        let earlier = Self.session(.finished, startedAt: Self.now.addingTimeInterval(-600))
        #expect(!AutopilotContinuation.shouldStartAgain(after: earlier, run: old), "A session of an earlier run")
    }

    // MARK: - Nobody working

    @Test func aSessionThatEndedSaysSoWithItsLastWords() {
        let run = Self.run()
        let ended = AutopilotContinuation.stall(of: run, session: Self.session(.finished, said: "  Only iPhone Duo is left.\n"), now: Self.now)
        #expect(ended == .ended(lastWords: "Only iPhone Duo is left."))
        #expect(AutopilotContinuation.stall(of: run, session: Self.session(.stopped), now: Self.now) == .ended(lastWords: nil))
        #expect(AutopilotContinuation.stall(of: run, session: Self.session(.working), now: Self.now) == nil)
        let failed = Self.session(.failed(.notLoggedIn("Not logged in")))
        #expect(AutopilotContinuation.stall(of: run, session: failed, now: Self.now) == nil, "A failure has Try Again")
    }

    @Test func aRunAppLocalizerStartedWithNoSessionNowIsNotRunning() {
        #expect(AutopilotContinuation.stall(of: Self.run(), session: nil, now: Self.now) == .notRunning)
    }

    @Test func aPastedRunIsQuietAfterHalfAnHour() {
        var run = Self.run(startsClaudeCode: nil)
        Self.captured(&run, after: 60)
        let last = Self.now.addingTimeInterval(60)
        #expect(AutopilotContinuation.stall(of: run, session: nil, now: last.addingTimeInterval(29 * 60)) == nil, "A build can take a while")
        #expect(AutopilotContinuation.stall(of: run, session: nil, now: last.addingTimeInterval(30 * 60)) == .quiet(since: last))
    }

    @Test func nothingStallsWhenTheAssistantHasNothingToDo() {
        var run = Self.run()
        AutopilotTestFixtures.captureAll(&run, except: [AutopilotTestFixtures.target("week")])
        run.problems = [AutopilotTestFixtures.problem(AutopilotTestFixtures.target("week"))]
        #expect(AutopilotContinuation.stall(of: run, session: Self.session(.finished), now: Self.now) == nil)
        #expect(AutopilotContinuation.stall(of: AutopilotTestFixtures.run(.waiting), session: nil, now: Self.now.addingTimeInterval(7200)) == nil)
    }

    // MARK: - Prompts

    @Test func theContinuingPromptPicksTheRunUpAndDoesntStopForOneDevice() {
        let prompt = AutopilotPrompt.continuing(appName: "Alba: Daily Motivation", appID: "6825428345")
        #expect(prompt.hasPrefix("Continue Alba: Daily Motivation’s screenshot run from AppLocalizer where it stopped: "
                + "call get_capture_plan for app 6825428345"))
        #expect(prompt.contains("affectsDevice: true"))
        #expect(prompt.contains("Keep going until next_step says done or wait"))
    }

    // MARK: - Through the launcher

    /// Claude Code ends after sending a capture: AppLocalizer starts it
    /// again with the prompt that continues the run, once. The second
    /// sends nothing, so it isn't started a third time.
    @Test func aSessionEndingWithWorkLeftStartsClaudeCodeAgainOnce() async throws {
        let clock = TestClock()
        let runner = FakeUnixScriptRunner()
        runner.lines = [
            ClaudeCodeTestFixtures.initLine(),
            ClaudeCodeTestFixtures.resultLine(text: "Captured Today; iPhone Duo can't run on this Mac."),
        ]
        let assistants = MCPTestFixtures.controller(server: FakeLocalHTTPServer(), clock: clock)
        let launcher = ClaudeCodeTestFixtures.launcher(assistants: assistants, runner: runner, clock: clock)
        let appID = ClaudeCodeTestFixtures.lumenID
        launcher.setProjectFolder(ClaudeCodeTestFixtures.lumenFolder, for: appID)
        await launcher.refreshHelper()

        var run = AutopilotTestFixtures.run(.capture)
        run.appID = appID
        run.startedAt = clock.now
        // Sent while the first session ran.
        run.captures = [AutopilotTestFixtures.capture(AutopilotTestFixtures.target("today"))]
        run.captures[0].receivedAt = clock.now
        let center = AutopilotCenter(runs: [appID: run])
        center.now = { clock.now }
        launcher.onRunEnded = { session in
            clock.advance(by: 60)
            Task { await AutopilotContinuation.sessionEnded(session, center: center, launcher: launcher) }
        }

        let first = await AutopilotContinuation.start(appID: appID, appName: "Lumen Journal", center: center, launcher: launcher)
        #expect(first != nil)
        await ClaudeCodeTestFixtures.waitForHelper(runner, runs: 2)
        await MCPTestFixtures.waitUntil { launcher.runs.count == 2 && launcher.runs.allSatisfy { !$0.isActive } }
        try await Task.sleep(for: .milliseconds(200))

        let sessions = runner.recordedArguments.filter { $0.first == "run" }
        #expect(sessions.count == 2)
        #expect(sessions.allSatisfy { arguments in arguments.contains { $0.hasPrefix("Continue Lumen Journal’s screenshot run from AppLocalizer") } })
        #expect(runner.recordedArguments.contains(["simulators"]), "This Mac's simulators are checked first")
        let continued = try #require(center.run(for: appID))
        #expect(continued.startsClaudeCode == true)
        #expect(continued.log.filter { $0.text == "Claude Code stopped with work left; AppLocalizer started it again" }.count == 1)
    }
}
#endif
