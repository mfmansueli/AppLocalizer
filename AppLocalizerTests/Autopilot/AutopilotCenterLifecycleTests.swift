//
//  AutopilotCenterLifecycleTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Run Autopilot…, the Plan step's edits, Cancel, Start and Stop, the
/// design project and the upload link's secret.
@MainActor
@Suite("Autopilot run lifecycle")
struct AutopilotCenterLifecycleTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = AutopilotTestFixtures.appID

    /// A finished run with every capture of the small plan.
    private var finishedRun: AutopilotRun {
        var run = AutopilotTestFixtures.run(.ready)
        AutopilotTestFixtures.captureAll(&run)
        run.environment = AutopilotEnvironment(xcode: "26.1", simulators: ["iPhone 17 Pro Max"])
        return run
    }

    @Test func runAutopilotOpensANewRunAtPlan() {
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        let run = center.prepare(appID: appID, versionString: "1.4", plan: AutopilotTestFixtures.smallPlan)

        #expect(run.id == "id-1")
        #expect(run.stage == .plan)
        #expect(run.versionString == "1.4")
        #expect(run.designKind == .claudeDesign)
        #expect(run.designName == "Northpier Brand")
        #expect(run.createdAt == AutopilotTestFixtures.now)
        #expect(run.startedAt == nil)
        #expect(run.captures.isEmpty)
        #expect(run.keptCaptureCount == 0)
        #expect(center.run(for: appID) == run)
    }

    @Test(arguments: [AutopilotStage.plan, .waiting, .capture, .pick, .design, .choose, .localize])
    func anOpenRunIsKeptWhenAutopilotIsRunAgain(stage: AutopilotStage) {
        center.install(AutopilotTestFixtures.run(stage))
        let run = center.prepare(appID: appID, versionString: "1.5", plan: AutopilotTestFixtures.singlePlan())

        #expect(run.id == "run-1")
        #expect(run.stage == stage)
        #expect(run.versionString == "1.4")
        #expect(run.plan == AutopilotTestFixtures.smallPlan)
    }

    @Test func aNewRunKeepsTheLastRunsCapturesThatStillFit() {
        let previous = finishedRun
        center.install(previous)
        var plan = AutopilotTestFixtures.smallPlan
        plan.displayTypes = [.iPhone]
        let run = center.prepare(appID: appID, versionString: "1.5", plan: plan)

        #expect(run.id == "id-1")
        #expect(run.versionString == "1.5")
        #expect(run.captures.count == 4)
        #expect(run.captures.allSatisfy { $0.target.displayType == .iPhone })
        #expect(run.keptCaptureCount == 4)
        #expect(run.environment == previous.environment)
        #expect(run.client == AutopilotTestFixtures.client)
    }

    @Test func planEditsCountTheKeptCapturesAgain() throws {
        center.install(finishedRun)
        center.prepare(appID: appID, versionString: "1.5", plan: AutopilotTestFixtures.smallPlan)
        #expect(center.run(for: appID)?.keptCaptureCount == 8)

        center.updatePlan(for: appID) { plan in
            plan.localeCodes = ["en-US"]
            plan.stopsToPick = false
        }
        let run = try #require(center.run(for: appID))
        #expect(run.plan.localeCodes == ["en-US"])
        #expect(!run.plan.stopsToPick)
        #expect(run.keptCaptureCount == 4)
        #expect(run.captures.count == 8, "The captures stay; only the count changes")
    }

    @Test func planEditsOnlyApplyAtPlan() {
        center.install(AutopilotTestFixtures.run(.capture))
        center.updatePlan(for: appID) { $0.stopsToPick = false }
        #expect(center.run(for: appID)?.plan.stopsToPick == true)
    }

    @Test func cancelBringsBackTheRunItReplaced() {
        let previous = finishedRun
        center.install(previous)
        center.prepare(appID: appID, versionString: "1.5", plan: AutopilotTestFixtures.singlePlan())
        center.cancelPlan(for: appID)
        #expect(center.run(for: appID) == previous)
    }

    @Test func cancellingAFirstRunRemovesIt() {
        center.prepare(appID: appID, versionString: "1.4", plan: AutopilotTestFixtures.smallPlan)
        center.cancelPlan(for: appID)
        #expect(center.run(for: appID) == nil)
    }

    @Test func startWaitsForTheAssistantWithAFreshUploadLink() throws {
        let planned = center.prepare(appID: appID, versionString: "1.4", plan: AutopilotTestFixtures.smallPlan)
        center.setDesignProject(StudioDebugRuns.northpier, for: appID)
        center.start(appID: appID)

        let run = try #require(center.run(for: appID))
        #expect(run.stage == .waiting)
        #expect(run.startedAt == AutopilotTestFixtures.now)
        #expect(run.finishedAt == nil)
        #expect(run.uploadToken != planned.uploadToken)
        #expect(run.designKind == .claudeDesign, "The design project is read again at Start")
        #expect(run.designName == "Northpier Brand")
        #expect(center.run(uploadToken: run.uploadToken)?.id == run.id)
        #expect(center.run(uploadToken: planned.uploadToken) == nil)

        center.start(appID: appID)
        #expect(center.run(for: appID)?.uploadToken == run.uploadToken, "Start only works at Plan")
    }

    @Test(arguments: [AutopilotStage.waiting, .capture])
    func stopGoesBackToThePlanAndKeepsTheCaptures(stage: AutopilotStage) throws {
        var run = AutopilotTestFixtures.run(stage)
        let today = AutopilotTestFixtures.target("today")
        let week = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        run.captures = [
            AutopilotTestFixtures.capture(today), AutopilotTestFixtures.capture(today, attempt: 2), AutopilotTestFixtures.capture(week),
        ]
        run.problems = [
            AutopilotTestFixtures.problem(AutopilotTestFixtures.target("week"), id: "pr-open"),
            AutopilotTestFixtures.problem(week, id: "pr-done", resolution: .captured),
        ]
        center.install(run)
        center.stop(appID: appID)

        let stopped = try #require(center.run(for: appID))
        #expect(stopped.stage == .plan)
        #expect(stopped.captures.count == 3)
        #expect(stopped.problems.map(\.id) == ["pr-done"])
        #expect(stopped.keptCaptureCount == 2)

        center.cancelPlan(for: appID)
        #expect(center.run(for: appID) == stopped, "Cancel doesn't drop a run that has started")
    }

    @Test(arguments: [AutopilotStage.pick, .design, .choose, .localize, .ready])
    func stopDoesNothingPastCapture(stage: AutopilotStage) {
        let run = AutopilotTestFixtures.run(stage)
        center.install(run)
        center.stop(appID: appID)
        center.cancelPlan(for: appID)
        #expect(center.run(for: appID) == run)
    }

    @Test func aFinishedRunsUploadLinkIsClosed() {
        center.install(AutopilotTestFixtures.run(.capture))
        #expect(center.run(uploadToken: "token-1")?.id == "run-1")
        #expect(center.run(uploadToken: "token-2") == nil)

        center.install(AutopilotTestFixtures.run(.ready))
        #expect(center.run(uploadToken: "token-1") == nil)
    }

    @Test func stoppingClosesTheUploadLinkUntilTheNextStart() {
        center.install(AutopilotTestFixtures.run(.capture))
        center.stop(appID: appID)
        #expect(center.run(for: appID)?.stage == .plan)
        #expect(center.run(uploadToken: "token-1") == nil)
    }

    @Test func uploadTokensAreLongRandomLowercaseHex() {
        let tokens = (0..<20).map { _ in AutopilotCenter.makeToken() }
        #expect(Set(tokens).count == 20)
        for token in tokens {
            #expect(token.count == 64)
            #expect(token.allSatisfy { $0.isHexDigit && !$0.isUppercase })
        }
    }

    @Test func noDesignProjectMeansTheStarters() {
        center.setDesignSummary(DesignSourceSummary(title: "Nothing"), for: appID)
        #expect(center.designProject(for: appID) == nil, "A summary needs a project")

        center.setDesignProject(DesignProject(kind: .figma, link: "https://figma.com/file/lumen"), for: appID)
        let summary = DesignSourceSummary(title: "Lumen · Figma file", typefaces: "SF Pro")
        center.setDesignSummary(summary, for: appID)
        #expect(center.designProject(for: appID)?.summary == summary)
        #expect(center.designProject(for: appID)?.displayName == "Lumen")

        center.setDesignProject(DesignProject(kind: .none, link: ""), for: appID)
        #expect(center.designProject(for: appID) == nil)
    }
}
#endif
