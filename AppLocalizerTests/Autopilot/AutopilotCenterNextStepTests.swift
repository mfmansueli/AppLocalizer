//
//  AutopilotCenterNextStepTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `next_step`'s answer at each stage: what the assistant does now, or how
/// long it waits.
@MainActor
@Suite("Autopilot next step")
struct AutopilotCenterNextStepTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = AutopilotTestFixtures.appID

    private func nextStep(environment: AutopilotEnvironment? = nil) async -> AutopilotNextStep {
        await center.nextStep(appID: appID, client: AutopilotTestFixtures.client, environment: environment)
    }

    @Test func withoutAStartedRunThereIsNothingToDo() async {
        #expect(await nextStep() == .noRun)
        center.install(AutopilotTestFixtures.run(.plan))
        #expect(await nextStep() == .noRun)
        #expect(center.run(for: appID)?.stage == .plan)
    }

    @Test func aWaitingRunIsPickedUpAndAsksForEveryTarget() async throws {
        center.install(AutopilotTestFixtures.run(.waiting))
        let step = await nextStep(environment: AutopilotEnvironment(xcode: "26.1"))

        #expect(step == .capture(targets: AutopilotTestFixtures.smallPlan.targets, retries: []))
        let run = try #require(center.run(for: appID))
        #expect(run.stage == .capture)
        #expect(run.client == AutopilotTestFixtures.client)
        #expect(run.environment?.xcode == "26.1")
    }

    @Test func capturingAsksForWhatsLeftAndTheRetries() async {
        let retried = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        let blocked = AutopilotTestFixtures.target("today", .iPad, "de-DE")
        var run = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&run, except: [retried, blocked, AutopilotTestFixtures.target("week", .iPad)])
        let retry = AutopilotTestFixtures.problem(retried, id: "pr-retry", resolution: .retryWithFix)
        run.problems = [retry, AutopilotTestFixtures.problem(blocked, id: "pr-open")]
        center.install(run)

        let step = await nextStep(environment: AutopilotEnvironment(simulators: ["iPad Pro 13″"]))
        #expect(step == .capture(targets: [AutopilotTestFixtures.target("week", .iPad), retried], retries: [retry]))
        #expect(center.run(for: appID)?.environment?.simulators == ["iPad Pro 13″"])
    }

    @Test func anOpenProblemWithNothingElseLeftWaitsForThePerson() async {
        let blocked = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        var run = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&run, except: [blocked])
        run.problems = [AutopilotTestFixtures.problem(blocked)]
        center.install(run)

        #expect(await nextStep() == .wait(reason: "A problem waits for the person: The photo picker asked for access and covered the entry.", seconds: 15))
    }

    @Test func everythingCapturedWaitsForTheNextStage() async {
        var run = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&run)
        center.install(run)
        #expect(await nextStep() == .wait(reason: "AppLocalizer is moving on to the next stage.", seconds: 5))
    }

    @Test(arguments: [(AutopilotStage.pick, "The person is picking the best captures."), (.choose, "The person is choosing a direction.")])
    func checkpointsWaitForThePerson(stage: AutopilotStage, reason: String) async {
        center.install(AutopilotTestFixtures.run(stage, design: .claudeDesign))
        #expect(await nextStep() == .wait(reason: reason, seconds: 20))
    }

    @Test func designingAsksForTheDirectionsStillToComeThenTheRevision() async {
        var run = StudioDebugRuns.run(.design)
        center.install(run)
        #expect(await nextStep() == .design(remaining: 2))

        run.directions = StudioDebugRuns.directions(design: true, of: run)
        center.install(run)
        #expect(await nextStep() == .wait(reason: "Every direction has arrived.", seconds: 5))

        run.revision = AutopilotRevisionRequest(note: "A lighter indigo", askedAt: AutopilotTestFixtures.now)
        center.install(run)
        #expect(await nextStep() == .revise(note: "A lighter indigo"))
    }

    @Test func startersNeedNoDesignAI() async {
        center.install(AutopilotTestFixtures.run(.design))
        #expect(await nextStep() == .wait(reason: "AppLocalizer is making directions from its starters.", seconds: 5))
    }

    @Test func localizingAsksForTheCaptionsThatDontFit() async {
        var run = AutopilotTestFixtures.run(.localize)
        center.install(run)
        #expect(await nextStep() == .wait(reason: "AppLocalizer is rendering and checking every screenshot.", seconds: 5))

        let overflow = AutopilotOverflow(locale: "de-DE", slot: 1, displayType: .iPhone, headline: "Deine ganze Woche", maxLines: 2, fill: 1.3)
        run.overflows = [overflow]
        center.install(run)
        #expect(await nextStep() == .writeCaptions([overflow]))
    }

    @Test func aReadyRunIsDone() async {
        center.install(AutopilotTestFixtures.run(.ready))
        #expect(await nextStep() == .done)
    }
}
#endif
