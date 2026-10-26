//
//  ScreenshotCheckerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The checks a render passes before it can go to Review & Push.
@MainActor
@Suite("ScreenshotChecker")
struct ScreenshotCheckerTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)

    private func layout(_ locale: StoreLocale, slot: Int, display: ScreenshotDisplayType = .iPhone) -> ScreenshotLayout {
        engine.layout(
            ScreenshotsSampleData.template, slot: slot, locale: locale, displayType: display,
            caption: ScreenshotsTestFixtures.caption(locale.code, slot: slot)
        )
    }

    private func capture(_ locale: String, slot: Int, size: PixelSize? = nil, localized: Bool = true) -> ResolvedCapture {
        ResolvedCapture(capture: ScreenshotsSampleData.capture(locale: locale, display: .iPhone, slot: slot, pixelSize: size), isInterfaceLocalized: localized)
    }

    @Test func aGoodRenderPassesEveryCheck() {
        let checks = ScreenshotChecker.checks(for: layout(.french, slot: 0), capture: capture("fr-FR", slot: 0), primaryLocaleName: "English (U.S.)")
        #expect(checks.map(\.kind) == [.sizeAndFormat, .glyphs, .fit])
        #expect(checks.allSatisfy { $0.status == .passed })
        #expect(checks.first?.text == "PNG · 1320 × 2868 px · RGB, no transparency")
        #expect(ScreenshotChecker.firstFailure(in: checks) == nil)
    }

    @Test func anIPadCaptureInAnIPhoneSlotIsTheWrongSize() throws {
        let checks = ScreenshotChecker.checks(
            for: layout(.korean, slot: 3), capture: capture("ko", slot: 3, size: PixelSize(width: 2064, height: 2752)),
            primaryLocaleName: "English (U.S.)"
        )
        let failure = try #require(ScreenshotChecker.firstFailure(in: checks))
        #expect(failure.kind == .captureSize)
        #expect(failure.shortReason == "Wrong size")
        #expect(failure.text.contains("2064 × 2752"))
        #expect(failure.text.contains("iPhone 17 Pro Max"))
    }

    @Test func theFirstFailureOfAnOverflowIsTheFit() throws {
        let checks = ScreenshotChecker.checks(for: layout(.german, slot: 2), capture: capture("de-DE", slot: 2), primaryLocaleName: "English (U.S.)")
        let failure = try #require(ScreenshotChecker.firstFailure(in: checks))
        #expect(failure.kind == .fit)
        #expect(failure.text == "Headline overflows: 1 line too many at 80 u")
    }

    @Test func aCaptureOfThePrimaryInterfaceIsOnlyAWarning() {
        let checks = ScreenshotChecker.checks(
            for: layout(.dutch, slot: 0), capture: capture("en-US", slot: 0, localized: false), primaryLocaleName: "English (U.S.)"
        )
        let warning = checks.first { $0.kind == .interfaceLocalized }
        #expect(warning?.status == .warning)
        #expect(warning?.text == "UI not localized: this capture shows the English (U.S.) interface")
        #expect(ScreenshotChecker.firstFailure(in: checks) == nil)
    }

    @Test func aMissingCaptureIsPendingNotFailed() {
        let checks = ScreenshotChecker.checks(for: layout(.french, slot: 0), capture: nil, primaryLocaleName: "English (U.S.)")
        #expect(checks.last?.kind == .capturePresent)
        #expect(checks.last?.status == .pending)
        #expect(ScreenshotChecker.firstFailure(in: checks) == nil)
    }
}
#endif
