//
//  AutopilotRetakeFlowTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Recording a moment again happens after Capture: uploads stay open for
/// it, Design waits for it, and Cancel or the person moving on ends it.
@MainActor
@Suite("App Preview moments · recording again after Capture")
struct AutopilotRetakeFlowTests {
    private typealias Fixtures = AutopilotTestFixtures

    /// Marked moments, the suggested ones waiting for a new take.
    private static func run(_ stage: AutopilotStage, retakes: Bool = true) -> AutopilotRun {
        var run = StudioDebugPick.picking()
        run.appID = Fixtures.appID
        run.stage = stage
        if retakes { run.momentRetakes = run.suggestedMomentIDs }
        return run
    }

    @Test func uploadsStayOpenOnlyWhileATakeIsWaiting() {
        for stage in [AutopilotStage.pick, .design, .choose] {
            #expect(Self.run(stage).takesUploads, "\(stage)")
            #expect(!Self.run(stage, retakes: false).takesUploads, "\(stage)")
        }
        #expect(Self.run(.waiting, retakes: false).takesUploads)
        #expect(Self.run(.capture, retakes: false).takesUploads)
        #expect(!Self.run(.localize).takesUploads)
    }

    @Test func theUploadTokenFollowsTheWait() {
        let center = Fixtures.center()
        let run = Self.run(.design)
        center.install(run)
        #expect(center.run(uploadToken: run.uploadToken)?.appID == run.appID)
        center.update(Fixtures.appID) { $0.momentRetakes = nil }
        #expect(center.run(uploadToken: run.uploadToken) == nil)
    }

    @Test func cancellingForgetsWhatWasAskedForAndApproved() {
        var run = Self.run(.design)
        run.motionRetakes = run.suggestedMomentIDs
        run.guidedReview = AutopilotGuidedReview(pushedAt: Fixtures.now)
        AutopilotCenter.resetForPlan(&run)
        #expect(run.stage == .plan)
        #expect(run.momentRetakes == nil)
        #expect(run.motionRetakes == nil)
        #expect(run.guidedReview == nil)
    }

    @Test func designWaitsForTheTakeThenGoesOn() async {
        let center = Fixtures.center()
        let context = Fixtures.context(Fixtures.services(center))
        var run = Self.run(.design)
        run.directions = StudioDebugRuns.run(.choose).directions
        center.install(run)

        await center.advance(Fixtures.appID, context: context)
        #expect(center.run(for: Fixtures.appID)?.stage == .design)

        center.update(Fixtures.appID) { $0.momentRetakes = nil }
        await center.advance(Fixtures.appID, context: context)
        #expect(center.run(for: Fixtures.appID)?.stage != .design)
    }

    @Test func thePersonGoingOnDropsTheWaitAndSaysSo() {
        var run = Self.run(.choose)
        run.giveUpWaitingRetakes(at: Fixtures.now)
        #expect(run.momentRetakes == nil)
        #expect(run.retakeTargets.isEmpty)
        #expect(run.log.last?.text.contains("Went on without recording") == true)
    }

    @Test func aWaitingTakeIsTheAssistantsWork() {
        #expect(Self.run(.design).assistantHasWork)
        #expect(Self.run(.choose).assistantHasWork)
    }
}
#endif
