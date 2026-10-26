//
//  CaptionFitTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The fit engine on the sample template: what fits, what shrinks, what
/// overflows, right-to-left alignment and the glyph check.
@MainActor
@Suite("Caption fit")
struct CaptionFitTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)

    private func layout(_ locale: StoreLocale, slot: Int, template: ScreenshotTemplate = ScreenshotsSampleData.template) -> ScreenshotLayout {
        engine.layout(template, slot: slot, locale: locale, displayType: .iPhone, caption: ScreenshotsTestFixtures.caption(locale.code, slot: slot))
    }

    @Test func germanSlotThreeOverflows() {
        let fit = layout(.german, slot: 2).headline
        #expect(!fit.fits)
        #expect(fit.tone == .overflows)
        #expect(fit.label == "1 line too many at 80 u")
        #expect(fit.size == 80)
    }

    @Test func englishSlotOneFitsAtFullSize() {
        let fit = layout(.englishUS, slot: 0).headline
        #expect(fit.fits)
        #expect(fit.tone == .fits)
        #expect(fit.fullSize == 112 * 1.06)
    }

    @Test func arabicIsAlignedRightAndRunsRightToLeft() throws {
        var template = ScreenshotsSampleData.template
        template.caption.align = .start
        let result = layout(.arabic, slot: 1, template: template)
        #expect(result.isRightToLeft)
        let line = try #require(result.lines.first)
        #expect(line.alignment == .right)
        #expect(line.isRightToLeft)
    }

    @Test func thaiWithALatinOnlyFontAndNoFallbackMissesGlyphs() throws {
        let thai = try #require(StoreLocaleCatalog.locale(code: "th"))
        var template = ScreenshotsSampleData.template
        template.fonts.display = "Northpier Display"
        template.caption.headline.font = "Northpier"
        template.fonts.fallback[.thai] = nil
        let result = layout(thai, slot: 0, template: template)
        #expect(!result.headlineFont.hasAllGlyphs)
        #expect(result.headlineFont.problem?.contains("Thai") == true)
        let checks = ScreenshotChecker.checks(for: result, capture: nil, primaryLocaleName: "English (U.S.)")
        #expect(checks.first { $0.kind == .glyphs }?.status == .failed)
    }

    @Test func thaiWithItsFallbackHasEveryGlyph() throws {
        let thai = try #require(StoreLocaleCatalog.locale(code: "th"))
        let result = layout(thai, slot: 0)
        #expect(result.headlineFont.hasAllGlyphs)
        #expect(result.headlineFont.isFallback)
    }

    @Test func theMeterPutsAnOverflowPastTheSecondTick() {
        let value = FitMeterValue(fit: layout(.german, slot: 2).headline)
        #expect(value.tone == .overflows)
        #expect(value.filled > value.smallestSizeTick)
        #expect(value.fullSizeTick < value.smallestSizeTick)
    }

    @Test func shrinkingStepsDownByTwoUnits() {
        let sizes = CaptionFitter().sizes(full: 112, minimum: 104, shrink: true)
        #expect(sizes == [112, 110, 108, 106, 104])
        #expect(CaptionFitter().sizes(full: 112, minimum: 80, shrink: false) == [112])
    }
}
#endif
