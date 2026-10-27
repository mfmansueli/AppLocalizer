//
//  StressStripPlannerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Which locales the stress strip shows and what each is previewed with.
@MainActor
@Suite("StressStripPlanner")
struct StressStripPlannerTests {
    private let planner = StressStripPlanner(engine: ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts))
    private let captions = ScreenshotsSampleData.captions(for: ScreenshotsSampleData.scope)

    private func inputs(
        slot: Int = 2,
        primary: StoreLocale = .englishUS,
        captions: CaptionBook? = nil,
        previews: [String: ScreenshotCaption] = [:]
    ) -> StressStripPlanner.Inputs {
        let book = captions ?? self.captions
        return StressStripPlanner.Inputs(
            template: ScreenshotsSampleData.template, slot: slot, displayType: .iPhone, primary: primary,
            ownCaption: { book.caption(locale: $0, slot: slot) },
            previewCaption: { previews[$0] },
            capture: { _ in nil }
        )
    }

    @Test func theStripIsThePrimaryTheLongestArabicAndJapanese() {
        let entries = planner.entries(inputs())
        #expect(entries.map(\.locale.code) == ["en-US", "de-DE", "ar-SA", "ja"])
        #expect(entries.map(\.roleText) == ["Primary", "Longest", "Right to left", "CJK"])
        #expect(entries[1].preview.fit.tone == .overflows)
        #expect(entries.allSatisfy { $0.captionSource == .own })
    }

    @Test func aLongerFinnishPreviewTakesTheLongestCard() throws {
        let long = ScreenshotCaption(headline: "Hae vuosien päiväkirjamerkinnöistä nopeasti ja vaivattomasti kaikkialla", provenance: .machineTranslated)
        let entries = planner.entries(inputs(slot: 0, previews: ["fi": long]))
        let longest = try #require(entries.first { $0.role == .longest })
        #expect(longest.locale.code == "fi")
        #expect(longest.captionSource == .previewTranslation)
        #expect(longest.roleText == "Longest · preview translation")
    }

    @Test func aShorterFinnishPreviewLeavesGermanLongest() {
        let short = ScreenshotCaption(headline: "Haku", provenance: .machineTranslated)
        let entries = planner.entries(inputs(previews: ["fi": short]))
        #expect(entries.first { $0.role == .longest }?.locale.code == "de-DE")
    }

    @Test func aLocaleWithoutACaptionShowsThePrimaryUntilItsPreviewArrives() {
        var book = CaptionBook()
        book.setCaption(ScreenshotCaption(headline: "Search years of entries in seconds"), locale: "en-US", slot: 2)
        let entries = planner.entries(inputs(captions: book))
        let arabic = entries.first { $0.role == .rightToLeft }
        #expect(arabic?.captionSource == .primaryStandIn)
        #expect(arabic?.caption?.headline == "Search years of entries in seconds")
        #expect(arabic?.roleText == "Right to left · no caption yet")
    }

    @Test func aGermanPrimaryMeasuresFinnishForTheLongest() {
        let german = StoreLocaleCatalog.locale(code: "de-DE") ?? .englishUS
        let entries = planner.entries(inputs(primary: german))
        #expect(entries.map(\.locale.code) == ["de-DE", "fi", "ar-SA", "ja"])
    }

    @Test func noCaptionsAtAllStillLaysOutTheSlot() {
        let entries = planner.entries(inputs(captions: CaptionBook()))
        #expect(entries.count == 4)
        #expect(entries.allSatisfy { $0.captionSource == .none && $0.caption == nil })
    }
}
#endif
