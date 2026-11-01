//
//  AutopilotCenterProblemGroupTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The person's answer to problems with one cause, and what a change to
/// the project does to the plan and to the other languages.
@MainActor
@Suite("Autopilot grouped problems")
struct AutopilotCenterProblemGroupTests {
    private let center = AutopilotTestFixtures.center()
    private let context: AutopilotContext
    private let appID = AutopilotTestFixtures.appID
    private static let fix = "In LumenUITests/ScreenshotTests.swift:64, tap app.buttons[\"journal.week\"]."

    init() {
        context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    /// The small plan in English, German and Japanese, capturing.
    private func installThreeLanguages() {
        var plan = AutopilotTestFixtures.smallPlan
        plan.localeCodes = ["en-US", "de-DE", "ja"]
        center.install(AutopilotTestFixtures.run(.capture, plan: plan))
    }

    private func report(_ display: ScreenshotDisplayType, _ locale: String, changesProject: Bool? = nil) throws -> AutopilotProblem {
        try center.reportProblem(
            appID: appID, target: AutopilotTestFixtures.target("week", display, locale),
            what: "testWeek taps app.buttons[\"Week\"], the English title.", proposedFix: Self.fix, changesProject: changesProject
        )
    }

    @Test func theAssistantCanSayTheFixChangesTheProject() throws {
        installThreeLanguages()
        let told = try report(.iPhone, "ja", changesProject: true)
        #expect(told.changesProject == true)
        #expect(told.needsProjectChange)
        let untold = try report(.iPad, "ja")
        #expect(untold.changesProject == nil)
        #expect(untold.needsProjectChange, "The fix doesn't read as a command")
    }

    @Test func retryingAChangeToTheProjectAddsNothingToThePlan() async throws {
        installThreeLanguages()
        let problem = try report(.iPhone, "ja")
        await center.resolveProblem(appID: appID, problemID: problem.id, with: .retryWithFix, context: context)
        let run = try #require(run)
        #expect(run.plan.simulator.extraCommands.isEmpty)
        #expect(run.retries.map(\.id) == [problem.id])
    }

    @Test func oneAnswerCoversEveryProblemInTheGroup() async throws {
        installThreeLanguages()
        let first = try report(.iPhone, "ja")
        let second = try report(.iPad, "ja")
        let group = try #require(run?.problemGroups.first)
        #expect(run?.problemGroups.count == 1)
        #expect(group.problems.map(\.id) == [first.id, second.id])

        await center.resolveProblems(appID: appID, problemIDs: group.problems.map(\.id), with: .retryWithFix, context: context)
        let run = try #require(run)
        #expect(run.openProblems.isEmpty)
        #expect(run.retries.map(\.id) == [first.id, second.id])
        #expect(run.plan.simulator.extraCommands.isEmpty)
    }

    @Test func thePrimaryCaptureForAChangeToTheProjectCoversTheOtherLanguages() async throws {
        installThreeLanguages()
        let problem = try report(.iPhone, "ja")
        #expect(run?.remainingTargets.contains(AutopilotTestFixtures.target("week", .iPhone, "de-DE")) == false, "German waits")

        await center.resolveProblem(appID: appID, problemID: problem.id, with: .usePrimaryCapture, context: context)
        let run = try #require(run)
        #expect(run.isSettled(AutopilotTestFixtures.target("week", .iPhone, "ja")))
        #expect(run.isSettled(AutopilotTestFixtures.target("week", .iPhone, "de-DE")), "The project stays as it is this run")
        #expect(!run.isSettled(AutopilotTestFixtures.target("week", .iPad, "de-DE")))
        #expect(!run.remainingTargets.contains(AutopilotTestFixtures.target("week", .iPhone, "de-DE")))
    }

    @Test func thePrimaryCaptureForACommandFixCoversOnlyItsLanguage() async throws {
        installThreeLanguages()
        let problem = try center.reportProblem(
            appID: appID, target: AutopilotTestFixtures.target("week", .iPhone, "ja"), what: "The photo picker covered it.",
            proposedFix: "xcrun simctl privacy booted grant photos com.northpier.lumen"
        )
        await center.resolveProblem(appID: appID, problemID: problem.id, with: .usePrimaryCapture, context: context)
        let run = try #require(run)
        #expect(run.primaryCaptureTargets == nil)
        #expect(run.remainingTargets.contains(AutopilotTestFixtures.target("week", .iPhone, "de-DE")), "German is tried again")
    }

    @Test func nextStepGivesTheRehearsalFirst() async {
        installThreeLanguages()
        let step = await center.nextStep(appID: appID, client: "Claude Code")
        guard case let .capture(targets, retries) = step else {
            Issue.record("Expected a capture step, got \(step)")
            return
        }
        #expect(Set(targets.map(\.locale)) == ["en-US", "ja"])
        #expect(targets.count == 8)
        #expect(retries.isEmpty)
    }
}
#endif
