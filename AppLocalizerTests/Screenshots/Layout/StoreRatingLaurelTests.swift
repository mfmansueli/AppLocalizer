//
//  StoreRatingLaurelTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// A laurel's number comes from the App Store, per country: German
/// screenshots show Germany's rating written the German way, a country
/// without ratings has no laurel, and a typed value stays typed and is
/// checked. In landscape, laurels, badges and sparkles keep their portrait
/// size and stay inside the canvas.
@MainActor
@Suite("Store-rated laurels")
struct StoreRatingLaurelTests {
    private let proof = ScreenshotTemplate.starter(.socialProof, id: "lumen", title: "Lumen")

    private static var ratings: StoreRatings {
        var ratings = StoreRatings.unchecked
        ratings.record(.rated(4.8), count: 220, inCountry: "US")
        ratings.record(.rated(4.72), count: 64, inCountry: "DE")
        ratings.record(.rated(4.85), count: 12, inCountry: "SA")
        ratings.record(.unrated, inCountry: "KR")
        return ratings
    }

    private func laurel(
        _ template: ScreenshotTemplate? = nil, locale: StoreLocale, ratings: StoreRatings = Self.ratings, display: ScreenshotDisplayType = .iPhone
    ) -> LayoutDecoration? {
        let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts, ratings: ratings)
        let layout = engine.layout(template ?? proof, slot: 0, locale: locale, displayType: display, caption: ScreenshotCaption(headline: "Write"))
        return layout.decorations.first { $0.kind == .laurel }
    }

    @Test func germanScreenshotsShowGermanysRating() {
        #expect(laurel(locale: .german)?.text == "4,7", "Germany's 4.72, with a decimal comma")
        #expect(laurel(locale: .englishUS)?.text == "4.8")
        #expect(laurel(locale: .german)?.isFromStore == true)
    }

    @Test func arabicKeepsLatinDigits() throws {
        let text = try #require(laurel(locale: .arabic)?.text)
        #expect(text.hasPrefix("4"), "Latin digits, not ٤")
        #expect(text.hasSuffix("9"), "4.85 rounds up, as the App Store shows it")
    }

    @Test func aCountryWithoutRatingsHasNoLaurel() {
        #expect(laurel(locale: .korean) == nil)
    }

    /// The render key tells a laurel left out (no rating in the country)
    /// from one showing the template's sample before the App Store
    /// answered, so the sample "4.9" render isn't used again for an app
    /// that has no ratings.
    @Test func aLaurelLeftOutForWantOfARatingChangesTheRenderKey() {
        let caption = ScreenshotCaption(headline: "Write")
        let unread = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts, ratings: .unchecked)
            .layout(proof, slot: 0, locale: .korean, displayType: .iPhone, caption: caption)
        let unrated = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts, ratings: Self.ratings)
            .layout(proof, slot: 0, locale: .korean, displayType: .iPhone, caption: caption)
        #expect(unread.decorations.contains { $0.kind == .laurel }, "Not answered yet: the sample")
        #expect(!unrated.decorations.contains { $0.kind == .laurel })
        #expect(unread.storeSignature == nil)
        #expect(unrated.storeSignature != nil)
        #expect(unrated.unratedLaurels == 1)
    }

    @Test func anUnreadRatingShowsTheTemplatesValueAndWarns() throws {
        let shown = try #require(laurel(locale: .japanese))
        #expect(shown.text == "4.8")
        #expect(!shown.isFromStore)
    }

    @Test func aTypedValueStaysAndIsChecked() throws {
        var template = proof
        var decorations = try #require(template.resolved(forSlot: 0).decorations)
        decorations[0].source = .custom
        decorations[0].value = "4.9"
        template.slots[0].over["deco"] = ScreenshotTemplate.encoded(decorations)
        #expect(laurel(template, locale: .german)?.text == "4.9")
        let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts, ratings: Self.ratings)
        let layout = engine.layout(template, slot: 0, locale: .german, displayType: .iPhone, caption: ScreenshotCaption(headline: "Write"))
        let check = ScreenshotChecker.checks(for: layout, capture: nil, primaryLocaleName: "English", ratings: Self.ratings).first { $0.kind == .rating }
        #expect(check?.status == .failed, "4.9 typed, but Germany shows 4.7")
        #expect(layout.storeSignature == nil, "Typed values are in the template's own key")
    }

    @Test func theSourceSurvivesJSON() throws {
        let typed = try JSONDecoder().decode(
            TemplateDecoration.self,
            from: Data(##"{"type": "laurel", "x": 0.3, "y": 0.8, "w": 0.4, "color": "#FFFFFF", "z": "front", "value": "4.6", "src": "custom"}"##.utf8)
        )
        #expect(typed.source == .custom)
        #expect(!typed.showsStoreRating)
        let plain = TemplateDecoration.laurel(x: 0.3, y: 0.8, width: 0.4, color: "#FFFFFF", value: "4.8")
        #expect(plain.showsStoreRating, "A laurel shows the App Store's rating unless typed")
        #expect(!TemplateDecoration.badge(x: 0, y: 0, width: 0.3, color: "#000000", ink: "#FFFFFF", value: "4.8 ★").showsStoreRating)
    }

    // MARK: - Landscape

    @Test(arguments: [ScreenshotDisplayType.iPad, .mac])
    func landscapeLaurelsKeepTheirPortraitSizeInsideTheCanvas(display: ScreenshotDisplayType) throws {
        let portrait = try #require(laurel(locale: .englishUS))
        let wide = try #require(laurel(locale: .englishUS, display: display))
        let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
        let canvas = engine.layout(proof, slot: 0, locale: .englishUS, displayType: display, caption: nil).canvas
        let portraitCanvas = engine.layout(proof, slot: 0, locale: .englishUS, displayType: .iPhone, caption: nil).canvas
        let shortSide = min(canvas.width, canvas.height)
        #expect(abs(wide.frame.width / shortSide - portrait.frame.width / portraitCanvas.width) < 0.001, "Same share of the short side")
        #expect(abs(wide.frame.width / wide.frame.height - portrait.frame.width / portrait.frame.height) < 0.01, "Same proportions")
        let bounds = CGRect(origin: .zero, size: canvas.size)
        #expect(bounds.contains(wide.frame), "Clamped inside the canvas")
    }

    @Test func landscapeSparklesKeepTheirSizeToo() throws {
        let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
        let ipad = engine.layout(proof, slot: 2, locale: .englishUS, displayType: .iPad, caption: nil)
        let sparkles = ipad.decorations.filter { $0.shape == .sparkle }
        #expect(sparkles.count == 2)
        let short = min(ipad.canvas.width, ipad.canvas.height)
        #expect(try abs(#require(sparkles.first).frame.width - 0.12 * short) < 1)
        let moon = try #require(ipad.decorations.first { $0.shape == .moon })
        #expect(abs(moon.frame.width - 0.62 * ipad.canvas.width) < 1, "Other shapes follow the canvas width")
    }

    // MARK: - Lookup

    @Test func ratingTextFollowsTheLocale() {
        #expect(ScreenshotLayoutEngine.ratingText(4.75, locale: .french) == "4,8")
        #expect(ScreenshotLayoutEngine.ratingText(4.0, locale: .englishUS) == "4.0")
    }
}
