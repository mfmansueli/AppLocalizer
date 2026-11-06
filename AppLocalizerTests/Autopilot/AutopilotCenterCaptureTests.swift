//
//  AutopilotCenterCaptureTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The assistant's side of capturing: picking the plan up, captures with
/// their size check, problems and the person's answers, and moving on once
/// every screen is settled.
@MainActor
@Suite("Autopilot captures and problems")
struct AutopilotCenterCaptureTests {
    private let center = AutopilotTestFixtures.center()
    private let context: AutopilotContext
    private let appID = AutopilotTestFixtures.appID

    init() {
        context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
    }

    private func receive(
        _ target: AutopilotCaptureTarget, file: CaptureFile? = nil, attempt: Int = 1, score: Double = 0.9
    ) async throws -> AutopilotCapture {
        let report = AutopilotCaptureReport(target: target, attempt: attempt, score: score, notes: "Prompt card, no keyboard")
        return try await center.receiveCapture(
            appID: appID, file: file ?? AutopilotTestFixtures.file(target.displayType), report: report, context: context
        )
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    // MARK: - Picking up

    @Test func askingForThePlanPicksTheRunUp() throws {
        center.install(AutopilotTestFixtures.run(.waiting))
        let environment = AutopilotEnvironment(xcode: "26.1", simulators: ["iPhone 17 Pro Max", "iPad Pro 13″"])
        center.pickUp(appID: appID, client: "Claude Code", environment: environment)

        let run = try #require(run)
        #expect(run.stage == .capture)
        #expect(run.client == "Claude Code")
        #expect(run.environment?.summary == "Xcode 26.1 · iPhone 17 Pro Max and iPad Pro 13″ simulators")
        #expect(run.log.last?.text == "Claude Code picked up the plan")
        #expect(run.log.last?.kind == .event)
        #expect(run.log.last?.date == AutopilotTestFixtures.now)
    }

    @Test func pickingUpAgainOnlyUpdatesTheEnvironment() throws {
        center.install(AutopilotTestFixtures.run(.capture))
        center.pickUp(appID: appID, client: "Codex", environment: AutopilotEnvironment(xcode: "Xcode 26.2"))

        let run = try #require(run)
        #expect(run.client == "Claude Code")
        #expect(run.environment?.summary == "Xcode 26.2")
        #expect(run.log.isEmpty)
    }

    // MARK: - Captures

    @Test func aCaptureIsRecordedWithItsAttemptScoreAndLogLine() async throws {
        center.install(AutopilotTestFixtures.run(.capture))
        let target = AutopilotTestFixtures.target("week", .iPhone, "de-DE")
        let capture = try await receive(target, file: AutopilotTestFixtures.file(.iPhone, id: "9f2c"), attempt: 2, score: 0.8)

        #expect(capture.id == "id-1")
        #expect(capture.target == target)
        #expect(capture.attempt == 2)
        #expect(capture.score == 0.8)
        #expect(capture.notes == "Prompt card, no keyboard")
        #expect(capture.captureID == "9f2c")
        #expect(capture.receivedAt == AutopilotTestFixtures.now)
        let run = try #require(run)
        #expect(run.captures == [capture])
        #expect(run.stage == .capture)
        #expect(run.log.last?.text == "screenshot → de-DE/iPhone-02.png · Week · attempt 2")
    }

    @Test(arguments: [(0, 1.7, 1, 1.0), (-2, -0.3, 1, 0.0), (3, 0.42, 3, 0.42)])
    func attemptsAndScoresAreKeptInRange(attempt: Int, score: Double, keptAttempt: Int, keptScore: Double) async throws {
        center.install(AutopilotTestFixtures.run(.capture))
        let capture = try await receive(AutopilotTestFixtures.target("today"), attempt: attempt, score: score)
        #expect(capture.attempt == keptAttempt)
        #expect(capture.score == keptScore)
    }

    @Test func aCaptureOfTheSameAttemptReplacesTheEarlierOne() async throws {
        center.install(AutopilotTestFixtures.run(.capture))
        let target = AutopilotTestFixtures.target("today")
        _ = try await receive(target, attempt: 1, score: 0.4)
        _ = try await receive(target, attempt: 2, score: 0.6)
        let again = try await receive(target, attempt: 1, score: 0.95)

        let captures = try #require(run).captures(for: target)
        #expect(captures.map(\.attempt) == [1, 2])
        #expect(captures.first == again)
    }

    @Test func aCaptureMustHaveTheDevicesSizeEitherWayUp() async throws {
        center.install(AutopilotTestFixtures.run(.capture))
        let target = AutopilotTestFixtures.target("today", .iPad)
        let expected = AutopilotError(
            "A 1320 × 2868 capture doesn’t fit iPad 13″, which takes 2064 × 2752 or 2752 × 2064. Capture on iPad Pro 13-inch (M5)."
        )
        await #expect(throws: expected) {
            try await receive(target, file: AutopilotTestFixtures.file(.iPhone))
        }
        #expect(run?.captures.isEmpty == true)

        let landscape = try await receive(target, file: AutopilotTestFixtures.file(.iPad, landscape: true))
        #expect(landscape.pixelSize == PixelSize(width: 2752, height: 2064))
    }

    @Test(arguments: [AutopilotStage.plan, .pick, .design, .choose, .localize, .ready])
    func capturesAndProblemsAreRefusedOutsideCapture(stage: AutopilotStage) async throws {
        center.install(AutopilotTestFixtures.run(stage))
        let target = AutopilotTestFixtures.target("today")
        let refusal = AutopilotError("The run isn’t capturing now. Call next_step to see what AppLocalizer wants.")
        await #expect(throws: refusal) { try await receive(target) }
        #expect(throws: refusal) {
            try center.reportProblem(appID: appID, target: target, what: "Blank", proposedFix: nil)
        }
        #expect(run?.stage == stage)
    }

    @Test func aWaitingRunTakesCapturesToo() async throws {
        center.install(AutopilotTestFixtures.run(.waiting))
        _ = try await receive(AutopilotTestFixtures.target("today"))
        #expect(run?.captures.count == 1)
    }

    // MARK: - Moving on

    @Test func theLastCaptureStopsForThePersonToPickTheBest() async throws {
        let last = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        var start = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&start, except: [last])
        start.captures.append(AutopilotTestFixtures.capture(AutopilotTestFixtures.target("today"), attempt: 2, score: 0.97))
        center.install(start)
        _ = try await receive(last)

        let run = try #require(run)
        #expect(run.stage == .pick)
        #expect(run.isCaptureComplete)
        #expect(run.picks["today"] == "cap-today-iphone-en-US-2")
        #expect(run.picks["week"] == "cap-week-iphone-en-US-1")
        #expect(run.log.last?.text == "Captured 8 of 8")
    }

    @Test func withoutPickingTheRunBriefsTheDesignAI() async throws {
        var plan = AutopilotTestFixtures.smallPlan
        plan.stopsToPick = false
        let last = AutopilotTestFixtures.target("today", .iPad, "de-DE")
        var start = AutopilotTestFixtures.run(.capture, plan: plan, design: .claudeDesign)
        AutopilotTestFixtures.captureAll(&start, except: [last])
        center.install(start)
        _ = try await receive(last)

        let run = try #require(run)
        #expect(run.stage == .design)
        #expect(run.picks.count == 2)
        #expect(run.directions.isEmpty)
        #expect(run.log.last?.text == "Brief ready for Claude Design: 2 captures, 2 languages")
        #expect(run.log.last?.kind == .command)
    }

    @Test func heldStagesDontMoveOn() async throws {
        center.holdsStages = true
        let last = AutopilotTestFixtures.target("today")
        var start = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&start, except: [last])
        center.install(start)
        _ = try await receive(last)

        #expect(run?.stage == .capture)
        #expect(run?.isCaptureComplete == true)
        #expect(run?.picks.isEmpty == true)
    }

    // MARK: - Problems

    @Test func aProblemBlocksOnlyItsScreen() throws {
        center.install(AutopilotTestFixtures.run(.capture))
        let target = AutopilotTestFixtures.target("week", .iPhone, "de-DE")
        let problem = try center.reportProblem(appID: appID, target: target, what: "The photo picker covered the entry.", proposedFix: "grant photos")

        #expect(problem.id == "pr-id-1")
        #expect(problem.isOpen)
        #expect(problem.reportedAt == AutopilotTestFixtures.now)
        let run = try #require(run)
        #expect(run.openProblems == [problem])
        #expect(run.remainingTargets.count == 7)
        #expect(!run.remainingTargets.contains(target))
        #expect(run.log.last?.text == "Week (de-DE): The photo picker covered the entry.")
        #expect(run.log.last?.kind == .problem)

        let again = try center.reportProblem(appID: appID, target: target, what: "Still covered.", proposedFix: nil)
        #expect(self.run?.problems == [again], "A new report replaces the open one")
    }

    @Test func aCaptureOfAProblemsScreenSolvesIt() async throws {
        let target = AutopilotTestFixtures.target("week", .iPhone, "de-DE")
        var start = AutopilotTestFixtures.run(.capture)
        start.problems = [AutopilotTestFixtures.problem(target)]
        center.install(start)
        _ = try await receive(target)

        let run = try #require(run)
        #expect(run.problems.first?.resolution == .captured)
        #expect(run.openProblems.isEmpty)
    }

    @Test func retryingWithTheFixAddsItToThePlanOnce() async throws {
        let first = AutopilotTestFixtures.target("week", .iPhone, "de-DE")
        let second = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        var start = AutopilotTestFixtures.run(.capture)
        start.problems = [AutopilotTestFixtures.problem(first, id: "pr-1"), AutopilotTestFixtures.problem(second, id: "pr-2")]
        center.install(start)
        await center.resolveProblem(appID: appID, problemID: "pr-1", with: .retryWithFix, context: context)
        await center.resolveProblem(appID: appID, problemID: "pr-2", with: .retryWithFix, context: context)

        let run = try #require(run)
        #expect(run.plan.simulator.extraCommands == ["xcrun simctl privacy booted grant photos com.northpier.lumen"])
        #expect(run.retries.map(\.id) == ["pr-1", "pr-2"])
        #expect(run.remainingTargets.contains(first), "A retried screen is captured again")
        #expect(run.openProblems.isEmpty)
    }

    @Test func retryingAfterARefusedCommandAddsNothingToThePlan() async throws {
        let target = AutopilotTestFixtures.target("week", .iPhone, "de-DE")
        center.install(AutopilotTestFixtures.run(.capture))
        let problem = try center.reportProblem(
            appID: appID, target: target, what: "xcodebuild with a variable in front was refused.",
            proposedFix: "Add a scheme that sets LUMEN_SCREENSHOTS=1.", refusedCommand: "TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild test"
        )
        #expect(problem.wasRefused)
        #expect(problem.refusedCommand == "TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild test")
        await center.resolveProblem(appID: appID, problemID: problem.id, with: .retryWithFix, context: context)

        let run = try #require(run)
        #expect(run.plan.simulator.extraCommands.isEmpty, "The fix is a change to the project, not a command")
        #expect(run.retries.map(\.id) == [problem.id])
        #expect(run.remainingTargets.contains(target))

        // An empty command is no refusal.
        let other = try center.reportProblem(appID: appID, target: target, what: "Blank", proposedFix: nil, refusedCommand: "")
        #expect(other.refusedCommand == nil)
        #expect(!other.wasRefused)
    }

    /// MB Admin's run: a portrait iPad capture reported as a problem (the
    /// tests can't rotate), retried without the change; Claude Code can't
    /// make it, so it reports it again, and the person keeps the capture.
    @Test func aCapturedScreensProblemCanBeKeptAfterARetry() async throws {
        let target = AutopilotTestFixtures.target("week", .iPad, "en-US")
        var start = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&start)
        center.install(start)
        let reported = AutopilotTestFixtures.now.addingTimeInterval(3600)
        center.now = { reported }
        let first = try center.reportProblem(
            appID: appID, target: target, what: "The iPad stayed in portrait.",
            proposedFix: "In ScreenshotUITests.swift:12 set XCUIDevice.shared.orientation = .landscapeLeft.", changesProject: true
        )
        await center.resolveProblem(appID: appID, problemID: first.id, with: .retryWithFix, context: context)
        #expect(try #require(run).retries.map(\.id) == [first.id])
        #expect(try #require(run).stage == .capture)

        center.now = { reported.addingTimeInterval(60) }
        let again = try center.reportProblem(
            appID: appID, target: target, what: "The change isn't in the project yet.", proposedFix: first.proposedFix, changesProject: true
        )
        #expect(try #require(run).retries.isEmpty, "Reported again, it's open instead")
        #expect(try #require(run).hasCapture(for: target))

        await center.resolveProblem(appID: appID, problemID: again.id, with: .keptCapture, context: context)
        let run = try #require(run)
        #expect(run.openProblems.isEmpty)
        #expect(run.retries.isEmpty, "Keeping the capture doesn't bring the retry back")
        #expect(run.stage != .capture, "Everything is settled, so the run goes on")
    }

    @Test func aProblemFromBeforeRefusalsWereNotedStillReads() throws {
        let old = Data(
            #"{"id":"pr-1","target":{"screenID":"week","displayType":"APP_IPHONE_67","locale":"de-DE"},"what":"Blank","reportedAt":0}"#.utf8
        )
        let problem = try JSONDecoder().decode(AutopilotProblem.self, from: old)
        #expect(problem.refusedCommand == nil)
        #expect(!problem.wasRefused)
    }

    @Test func reusingThePrimaryCaptureSettlesTheLastScreen() async throws {
        let blocked = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        var start = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&start, except: [blocked])
        start.problems = [AutopilotTestFixtures.problem(blocked)]
        center.install(start)
        #expect(start.capturedCount == 7)
        #expect(!start.isCaptureComplete)

        await center.resolveProblem(appID: appID, problemID: "pr-1", with: .usePrimaryCapture, context: context)
        let run = try #require(run)
        #expect(run.capturedCount == 8)
        #expect(run.stage == .pick)
        #expect(run.plan.simulator.extraCommands.isEmpty)
    }
}
#endif
