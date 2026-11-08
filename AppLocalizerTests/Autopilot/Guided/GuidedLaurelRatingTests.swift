//
//  GuidedLaurelRatingTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A template's laurel shows the App Store rating, and none where the app
/// has no ratings yet (Bruma, not on the App Store): Look's template
/// preview and Choose's looks look the rating up and are laid out again,
/// instead of keeping the template's sample "4.9" the set won't show.
@MainActor
@Suite("Guided look · laurels follow the App Store rating")
struct GuidedLaurelRatingTests {
    /// The screenshots model, with an App Store that has no ratings for the
    /// app in any of its countries.
    private static func unratedApp(_ run: AutopilotRun) async throws -> ScreenshotsViewModel {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run))
        let services = try #require(model.services as? StudioTestServices)
        var none = StoreRatings.unchecked
        for country in Set(model.locales.map { $0.regionCode.uppercased() } + ["US"]) {
            none.record(.unrated, inCountry: country)
        }
        services.fake.ratings = none
        return model
    }

    private static func ratingTexts(_ layouts: [ScreenshotLayout]) -> [String] {
        layouts.flatMap(\.decorations).filter { $0.kind == .laurel }.compactMap(\.text)
    }

    @Test func thePreviewDropsTheSampleRatingOnceTheAppHasNone() async throws {
        let run = StudioDebugRuns.run(.plan)
        let model = try await Self.unratedApp(run)
        let before = try #require(model.studio.templatePreview(.cinema, plan: run.plan))
        let sample = Self.ratingTexts(before.items.map(\.job.layout))
        try #require(sample == ["4.9"], "Not looked up yet: Cinema's sample laurel")

        model.lookUpRatings(for: .cinema)
        await model.ratingsTask?.value
        let after = try #require(model.studio.templatePreview(.cinema, plan: run.plan))
        let laurels = after.items.flatMap(\.job.layout.decorations).filter { $0.kind == .laurel }
        #expect(laurels.isEmpty, "No ratings on the App Store: no laurel")
    }

    /// Cinema's laurel is on its 2nd slot: a set of one slot (Bruma's
    /// first template) would ask about no country at all.
    @Test func theLookUpCoversEverySlotTheTemplateCouldHave() async throws {
        let one = ScreenshotTemplate.starter(.cinema, id: "bruma", title: "Bruma", slotCount: 1)
        #expect(!one.showsRatings)
        let run = StudioDebugRuns.run(.plan)
        let model = try await Self.unratedApp(run)
        let services = try #require(model.services as? StudioTestServices)
        model.lookUpRatings(for: .cinema)
        await model.ratingsTask?.value
        let asked = services.fake.ratingLookups.last ?? []
        #expect(asked.contains("US"), "\(services.fake.ratingLookups)")
    }

    @Test func aLookIsLaidOutAgainOnceTheRatingIsKnown() async throws {
        let run = StudioDebugRuns.run(.choose)
        let model = try await Self.unratedApp(run)
        let direction = AutopilotDirection(
            id: "cinema", name: "Cinema", rationale: "Dark and calm.", source: .claudeDesign, client: "Claude Code",
            template: ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen"), receivedAt: Date(timeIntervalSince1970: 0)
        )
        let first = model.studio.layouts(for: direction)
        let sample = Self.ratingTexts(first)
        try #require(sample == ["4.9"], "Laid out before the answer")

        await model.ratingsTask?.value
        let again = model.studio.layouts(for: direction)
        #expect(Self.ratingTexts(again).isEmpty, "No ratings on the App Store: no laurel")
        #expect(again.count == first.count)
    }
}
#endif
