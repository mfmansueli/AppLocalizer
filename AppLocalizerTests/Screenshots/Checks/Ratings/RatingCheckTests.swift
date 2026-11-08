//
//  RatingCheckTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A laurel or badge must be true: no higher than the app's App Store
/// rating in the locale's country, and none before the app has one there.
/// A rating nobody could check only warns.
@MainActor
@Suite("Rating check")
struct RatingCheckTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
    /// Cinema's slot 2 carries a 4.9 laurel.
    private let cinema = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")

    private func layout(_ locale: StoreLocale = .englishUS, slot: Int = 1) -> ScreenshotLayout {
        engine.layout(cinema, slot: slot, locale: locale, displayType: .iPhone, caption: ScreenshotCaption(headline: "Watch anywhere"))
    }

    private func ratings(_ status: StoreRatings.Status, in country: String = "US") -> StoreRatings {
        var ratings = StoreRatings.unchecked
        ratings.record(status, inCountry: country)
        return ratings
    }

    private func check(_ layout: ScreenshotLayout, _ ratings: StoreRatings) -> RenderCheck? {
        ScreenshotChecker.checks(for: layout, capture: nil, primaryLocaleName: "English (U.S.)", ratings: ratings).first { $0.kind == .rating }
    }

    @Test func aSlotWithoutARatingHasNoRatingCheck() {
        #expect(check(layout(slot: 0), ratings(.unrated)) == nil)
    }

    @Test func aRatingAtTheStoresPasses() throws {
        // The App Store shows 4.86 as 4.9.
        let passed = try #require(check(layout(), ratings(.rated(4.86))))
        #expect(passed.status == .passed)
        #expect(passed.text.contains("4.9"))
    }

    @Test func aHigherRatingFailsTheRender() throws {
        let failed = try #require(check(layout(), ratings(.rated(4.7))))
        #expect(failed.status == .failed)
        #expect(failed.blocksPush)
        #expect(failed.shortReason == "Rating too high")
        #expect(failed.text.contains("4.9 shown"))
        #expect(failed.text.contains("4.7"))
    }

    @Test func aRatingBeforeTheAppHasOneFails() throws {
        let failed = try #require(check(layout(.german), ratings(.unrated, in: "DE")))
        #expect(failed.status == .failed)
        #expect(failed.shortReason == "No rating")
    }

    @Test func anUncheckedRatingOnlyWarns() throws {
        let warning = try #require(check(layout(.japanese), ratings(.rated(4.9))))
        #expect(warning.status == .warning, "Japan wasn't looked up")
        #expect(!warning.blocksPush)
    }

    /// A laurel follows the App Store's rating unless its value was
    /// typed: a typed 4.9 stays, and is checked.
    @Test func theMatrixFailsACellWhoseRatingIsTooHigh() throws {
        var document = ScreenshotsDebugDocuments.standard
        var history = try #require(document.history)
        var typed = cinema
        var decorations = try #require(typed.resolved(forSlot: 1).decorations)
        let laurel = try #require(decorations.firstIndex { $0.type == .laurel })
        decorations[laurel].source = .custom
        decorations[laurel].value = "4.9"
        typed.slots[1].over["deco"] = ScreenshotTemplate.encoded(decorations)
        history.save(typed, date: .now, note: "Cinema")
        document.history = history
        var snapshot = ScreenshotsTestFixtures.snapshot(document)
        snapshot.ratings = ratings(.rated(4.6))
        let matrix = ScreenshotMatrixBuilder().build(snapshot)
        let cell = try #require(matrix.cell(locale: "en-US", displayType: .iPhone, slot: 1))
        #expect(cell.checks.first { $0.kind == .rating }?.status == .failed)
        guard case .failed = cell.state else {
            Issue.record("A failed rating keeps the cell out of Review & Push: \(cell.state)")
            return
        }
        let other = try #require(matrix.cell(locale: "en-US", displayType: .iPhone, slot: 0))
        #expect(!other.checks.contains { $0.kind == .rating })
    }

    @Test func theCountriesAreTheLocalizedLocales() throws {
        var document = ScreenshotsDebugDocuments.standard
        #expect(document.ratingCountries(in: StoreLocaleCatalog.all).isEmpty, "No laurels, nothing to look up")
        var history = try #require(document.history)
        history.save(cinema, date: .now, note: "Cinema")
        document.history = history
        let countries = document.ratingCountries(in: StoreLocaleCatalog.all)
        #expect(countries.contains("US"))
        #expect(countries.contains("DE"))
        #expect(countries.allSatisfy { $0.count == 2 && $0 == $0.uppercased() })
    }

    @Test func theScreenshotsViewLooksTheRatingsUpOnce() async throws {
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        #expect(services.ratingLookups.isEmpty)
        var found = StoreRatings.unchecked
        found.record(.rated(4.9), inCountry: "US")
        services.ratings = found
        await model.chooseStarter(.cinema)
        await model.ratingsTask?.value
        #expect(services.ratingLookups.count == 1)
        #expect(services.ratingLookups.first?.contains("US") == true)
        #expect(model.ratings.status(inCountry: "US") == .rated(4.9))
        let cell = try #require(model.matrix.cell(locale: "en-US", displayType: .iPhone, slot: 1))
        #expect(cell.checks.first { $0.kind == .rating }?.status == .passed)
        await model.rebuild()
        #expect(services.ratingLookups.count == 1, "Each country is asked about once")
    }
}
#endif
