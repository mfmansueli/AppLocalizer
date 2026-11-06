//
//  AutopilotGuidedReviewTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What the person did at Review & push, kept on the run.
@MainActor
@Suite("AutopilotGuidedReview")
struct AutopilotGuidedReviewTests {
    @Test func approvingTwiceTakesItBack() {
        var review = AutopilotGuidedReview()
        review.toggle(.screenshots)
        review.toggle(.artwork)
        #expect(review.isApproved(.screenshots))
        #expect(review.approved == [.screenshots, .artwork])
        review.toggle(.screenshots)
        #expect(!review.isApproved(.screenshots))
        #expect(review.approved == [.artwork])
    }

    @Test func aShorteningIsConfirmedOnce() throws {
        let shortening = try #require(StudioDebugRuns.run(.ready).shortenings.first)
        #expect(AutopilotGuidedReview.key(shortening) == "de-DE#2")
        var review = AutopilotGuidedReview()
        review.confirm([shortening])
        review.confirm([shortening])
        #expect(review.confirmed == ["de-DE#2"])
        #expect(review.isConfirmed(shortening))
    }

    @Test func theRunKeepsIt() throws {
        var run = StudioDebugGuided.ready(approved: [.screenshots], pushed: true)
        run.guidedReview?.confirm(run.shortenings)
        let data = try JSONEncoder().encode(run)
        let decoded = try JSONDecoder().decode(AutopilotRun.self, from: data)
        #expect(decoded.guidedReview == run.guidedReview)

        run.guidedReview = nil
        let older = try JSONDecoder().decode(AutopilotRun.self, from: JSONEncoder().encode(run))
        #expect(older.guidedReview == nil, "A run from before the guided review has none")
    }

    @Test func theTabsAreWhatTheRunMakes() {
        let plan = StudioDebugGuided.planned().plan
        #expect(GuidedReviewPart.parts(of: plan) == [.screenshots, .artwork, .appPreview])
        #expect(GuidedReviewPart.parts(of: StudioDebugGuided.planned(screenshots: false, appPreview: false).plan) == [.artwork])
        #expect(GuidedReviewPart.screenshots.approveTitle(plan: plan) == "Approve Screenshots")
        #expect(GuidedReviewPart.artwork.approveTitle(plan: plan) == "Approve Header and Search")
    }

    @Test func theLookPickNamesTheDesignSource() {
        #expect(GuidedPick.label(design: .claudeDesign) == "Claude’s pick")
        #expect(GuidedPick.label(design: .none) == "AppLocalizer’s pick")
        let run = StudioDebugGuided.choosing
        #expect(GuidedPick.direction(in: run)?.id == run.directions.first?.id)
        #expect(GuidedPick.concept(in: run) == run.recommendedConcept)
    }
}
#endif
