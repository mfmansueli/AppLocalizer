//
//  GuidedReviewsPreviewTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Social Proof's Reviews screen quotes real 5-star App Store reviews: the
/// Look preview looks them up, and says when the app has none, so its
/// Reviews screen shows its capture instead.
@MainActor
@Suite("Guided look · the Reviews screen")
struct GuidedReviewsPreviewTests {
    /// The screenshots model, with an App Store that has no reviews for the
    /// app in any of its countries (Bruma, not on the App Store yet).
    private static func appWithoutReviews(_ run: AutopilotRun) async throws -> ScreenshotsViewModel {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run))
        let services = try #require(model.services as? StudioTestServices)
        var none = StoreReviews.none
        for country in Set(model.locales.map { $0.regionCode.uppercased() } + ["US"]) {
            none.record([], inCountry: country)
        }
        services.fake.reviews = none
        return model
    }

    @Test func thePreviewSaysTheReviewsScreenShowsItsCapture() async throws {
        let run = StudioDebugRuns.run(.plan)
        let model = try await Self.appWithoutReviews(run)
        let before = try #require(model.studio.templatePreview(.socialProof, plan: run.plan))
        try #require(before.items.contains { $0.job.layout.reviews != nil }, "Social Proof's 2nd screen is its Reviews screen")
        #expect(!before.note.contains("5-star"), "Not looked up yet: nothing to say")

        model.lookUpReviews(for: .socialProof)
        await model.reviewsTask?.value
        let after = try #require(model.studio.templatePreview(.socialProof, plan: run.plan))
        #expect(after.note.contains("has no 5-star App Store reviews in"), "\(after.note)")
        #expect(after.note.contains("the Reviews screen shows its capture instead"))
    }

    @Test func aTemplateWithoutAReviewsScreenSaysNothingOfReviews() async throws {
        let run = StudioDebugRuns.run(.plan)
        let model = try await Self.appWithoutReviews(run)
        model.lookUpReviews(for: .cinema)
        let preview = try #require(model.studio.templatePreview(.cinema, plan: run.plan))
        #expect(!preview.note.contains("5-star"))
    }
}
#endif
