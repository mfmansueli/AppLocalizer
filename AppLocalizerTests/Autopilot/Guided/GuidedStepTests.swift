//
//  GuidedStepTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The guided sheet's six steps: where a run is, and how the stepper
/// draws them.
@MainActor
@Suite("GuidedStep")
struct GuidedStepTests {
    @Test func aPlanIsAtTheSetupStepThePersonIsOn() {
        let plan = AutopilotTestFixtures.run(.plan)
        #expect(GuidedStep.step(of: nil, setup: .look) == .look, "No run yet: the setup step")
        #expect(GuidedStep.step(of: plan, setup: .make) == .make)
        #expect(GuidedStep.step(of: plan, setup: .plan) == .plan)
        #expect(GuidedStep.step(of: plan, setup: .review) == .make, "A plan is never past the setup")
    }

    @Test func everythingAutopilotDoesIsMakingIt() {
        for stage in [AutopilotStage.waiting, .capture, .pick, .design, .localize] {
            #expect(GuidedStep.step(of: AutopilotTestFixtures.run(stage), setup: .plan) == .making, "\(stage)")
        }
    }

    @Test func thePersonsStopsAreChooseAndReview() {
        #expect(GuidedStep.step(of: AutopilotTestFixtures.run(.choose), setup: .make) == .choose)
        #expect(GuidedStep.step(of: AutopilotTestFixtures.run(.watchPreview), setup: .make) == .review, "Watch is part of the review")
        #expect(GuidedStep.step(of: AutopilotTestFixtures.run(.ready), setup: .make) == .review)

        var pushed = AutopilotTestFixtures.run(.ready)
        pushed.guidedReview = AutopilotGuidedReview(pushedAt: AutopilotTestFixtures.now)
        #expect(GuidedStep.step(of: pushed, setup: .make) == .done)
    }

    @Test func theStepperShowsSixStepsAndMarksTheTwoStops() {
        #expect(GuidedStep.stepper.map(\.number) == [1, 2, 3, 4, 5, 6])
        #expect(GuidedStep.stepper.filter(\.isYours) == [.choose, .review])
        #expect(GuidedStep.stepper.filter(\.isSetup) == [.make, .look, .plan])
        #expect(GuidedStep.review.title == "Review & push")
        #expect(GuidedStep.stepper.map(\.identifier) == ["make", "look", "plan", "making", "choose", "review"])
    }

    @Test func localizingSitsBetweenChooseAndReview() {
        let localizing = AutopilotTestFixtures.run(.localize)
        let position = GuidedStep.position(of: localizing, setup: .make)
        #expect(GuidedStep.choose.state(at: position) == .done)
        #expect(GuidedStep.review.state(at: position) == .upcoming)
        #expect(GuidedStep.stepper.allSatisfy { $0.state(at: position) != .current }, "Nothing is current while it localizes")

        let capturing = GuidedStep.position(of: AutopilotTestFixtures.run(.capture), setup: .make)
        #expect(GuidedStep.plan.state(at: capturing) == .done)
        #expect(GuidedStep.making.state(at: capturing) == .current)
        #expect(GuidedStep.choose.state(at: capturing) == .upcoming)
    }
}
#endif
