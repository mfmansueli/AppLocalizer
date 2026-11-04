//
//  AutopilotCancelRunTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Cancel Run… after Capture: what this Mac makes stops, and the run goes
/// back to its plan with its captures and picks; before Pick captures and
/// once it's ready, it changes nothing.
@MainActor
@Suite("Autopilot Cancel Run")
struct AutopilotCancelRunTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = StudioDebugRuns.appID

    private var run: AutopilotRun? { center.run(for: appID) }

    @Test(arguments: [AutopilotStage.pick, .design, .choose, .localize, .watchPreview])
    func cancellingGoesBackToThePlanWithTheCaptures(stage: AutopilotStage) throws {
        var start = StudioDebugRuns.run(stage)
        start.templateVersion = stage == .localize ? 5 : nil
        start.previewReview = stage == .watchPreview ? AutopilotPreviewReview() : nil
        start.overflows = []
        center.install(start)

        center.cancelRun(appID: appID)

        let run = try #require(run)
        #expect(run.stage == .plan)
        #expect(run.captures == start.captures, "The captures stay for the next start")
        #expect(run.picks == start.picks)
        #expect(run.directions.isEmpty)
        #expect(run.chosenDirectionID == nil)
        #expect(run.revision == nil)
        #expect(run.templateVersion == nil)
        #expect(run.previewReview == nil)
        #expect(run.extrasProgress == nil)
        #expect(run.localeStatus.isEmpty)
        #expect(run.shortenings.isEmpty)
        #expect(run.openProblems.isEmpty)
        #expect(run.keptCaptureCount == run.keptTargetCount)
        #expect(run.log.last?.text == "Run cancelled at \(stage.title); the captures stay for the next start")
    }

    @Test(arguments: [AutopilotStage.plan, .waiting, .capture, .ready])
    func itChangesNothingBeforePickingOrOnceReady(stage: AutopilotStage) {
        let start = StudioDebugRuns.run(stage)
        center.install(start)
        center.cancelRun(appID: appID)
        #expect(run == start)
    }

    /// A cancelled run starts again from the captures it has.
    @Test func aCancelledRunStartsAgain() throws {
        center.install(StudioDebugRuns.run(.choose))
        center.cancelRun(appID: appID)
        center.start(appID: appID)
        let run = try #require(run)
        #expect(run.stage == .waiting)
        #expect(!run.captures.isEmpty)
    }

    /// What's being made stops at its next frame or file.
    @Test func cancellingStopsWhatsBeingMade() async {
        center.install(StudioDebugRuns.run(.localize))
        let work = Task {
            await center.cancellably(appID) { () async -> Bool in
                while !Task.isCancelled { try? await Task.sleep(for: .milliseconds(5)) }
                return true
            }
        }
        while center.making[appID] == nil { await Task.yield() }
        center.cancelRun(appID: appID)
        #expect(await work.value, "The work saw it was cancelled")
        #expect(center.making[appID] == nil)
        #expect(run?.stage == .plan)
    }

    @Test func theQuestionSaysWhatStays() {
        var run = StudioDebugRuns.run(.localize)
        run.templateVersion = nil
        let before = AutopilotCancelRunButton.message(for: run)
        #expect(before.contains("The captures and picks stay for the next start."))
        #expect(before.contains("Nothing was sent to App Store Connect."))
        #expect(!before.contains("Template v"))
        run.templateVersion = 5
        #expect(AutopilotCancelRunButton.message(for: run).contains("Template v5 is already saved and stays in the set’s history."))
    }
}
#endif
