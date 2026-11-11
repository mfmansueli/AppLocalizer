//
//  IPhoneDuoCoverDisplayTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// iPhone Duo's folded screenshots: every one is Apple's 2007 × 2853 (or
/// turned), a cover display capture framed inside it as the folded phone,
/// alone or beside the unfolded Duo (both, side by side) at the same
/// scale.
@MainActor
@Suite("iPhone Duo cover display")
struct IPhoneDuoCoverDisplayTests {
    private static let cover = CaptureSizeRules.duoOuterSize
    private static let inner = CaptureSizeRules.duoInnerSize
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)

    private func layout(
        captureSize: PixelSize?, companion: PixelSize? = nil, template: ScreenshotTemplate = ScreenshotsSampleData.template,
        locale: StoreLocale = .englishUS
    ) -> ScreenshotLayout {
        engine.layout(
            template, slot: 0, locale: locale, displayType: .iPhoneDuo,
            caption: ScreenshotsTestFixtures.caption("en-US", slot: 0), captureSize: captureSize, companionSize: companion
        )
    }

    private func capture(_ size: PixelSize) -> ScreenshotCapture {
        ScreenshotsSampleData.capture(locale: "en-US", display: .iPhoneDuo, slot: 0, pixelSize: size)
    }

    private static func aspect(_ rect: CGRect) -> CGFloat { rect.height / rect.width }

    @Test func everyDuoCanvasIsApplesSize() {
        #expect(ScreenshotCanvas(display: .iPhoneDuo, orientation: .portrait, isCoverDisplay: true).pixelSize == Self.inner)
        #expect(ScreenshotCanvas(display: .iPhoneDuo, orientation: .landscape, isCoverDisplay: true).pixelSize == Self.inner.rotated)
        #expect(layout(captureSize: Self.cover).canvas.pixelSize == Self.inner)
        #expect(layout(captureSize: Self.inner.rotated).canvas.pixelSize == Self.inner.rotated)
        #expect(layout(captureSize: nil).canvas.pixelSize == Self.inner)
    }

    @Test func aCoverCaptureIsTheFoldedPhoneInsideIt() throws {
        let folded = layout(captureSize: Self.cover)
        #expect(folded.canvas.isCoverDisplay)
        _ = try #require(folded.device)
        #expect(abs(Self.aspect(folded.screen) - ScreenshotLayoutEngine.coverAspect) < 0.01, "The screen takes the cover display's shape")
        #expect(ScreenshotChecker.captureSizeCheck(capture(Self.cover), layout: folded) == nil)
    }

    /// Band placement fills the canvas with the capture, which a folded
    /// phone can't: it stands under the band instead, and passes the size
    /// check.
    @Test func aBandKeepsTheFoldedPhoneWhole() throws {
        var band = ScreenshotsSampleData.template
        band.caption.placement = .band
        let folded = layout(captureSize: Self.cover, template: band)
        #expect(!folded.isFullBleed)
        _ = try #require(folded.device)
        let strip = try #require(folded.band)
        #expect(folded.screen.minY >= strip.maxY || folded.screen.maxY <= strip.minY)
        #expect(ScreenshotChecker.captureSizeCheck(capture(Self.cover), layout: folded) == nil)
        #expect(layout(captureSize: Self.inner, template: band).isFullBleed, "The inner display still fills it")
    }

    /// A template that lays iPhone Duo out landscape (for the inner
    /// display) frames a closed one in that canvas too: the cover capture
    /// doesn't turn it.
    @Test func aCoverCaptureKeepsTheSetsWay() throws {
        var canvas = TemplateCanvas(iphone: .portrait, ipad: .landscape)
        canvas.duo = .landscape
        #expect(canvas.following(Self.cover, on: .iPhoneDuo).duo == .landscape)
        #expect(TemplateCanvas(iphone: .portrait, ipad: .landscape).following(Self.cover, on: .iPhoneDuo).duo == nil)
        #expect(TemplateCanvas(iphone: .portrait, ipad: .landscape).following(Self.inner.rotated, on: .iPhoneDuo).duo == .landscape)

        var landscape = ScreenshotsSampleData.template
        landscape.canvas.duo = .landscape
        let folded = layout(captureSize: Self.cover, template: landscape)
        #expect(folded.canvas.pixelSize == Self.inner.rotated)
        #expect(folded.screen.height > folded.screen.width, "The folded phone stands up in it")
        // Whole, whatever the template lets a device do.
        let device = try #require(folded.device)
        #expect(device.frame.maxY <= folded.canvas.height)
    }

    /// Alba's closed screenshots looked like an iPhone: the template ran
    /// the folded phone off the bottom, hiding its squat shape, and drew
    /// an iPhone's four round corners. It stands whole, however far the
    /// template lets devices bleed or pins them down.
    @Test func theFoldedPhoneStandsWhole() throws {
        for orientation in [ScreenshotOrientation.portrait, .landscape] {
            var bleeding = ScreenshotsSampleData.template
            bleeding.canvas.duo = orientation
            bleeding.device.bleed = 0.3
            bleeding.device.width = 1.2
            bleeding.device.top = 0.9
            let folded = layout(captureSize: Self.cover, template: bleeding)
            let device = try #require(folded.device)
            #expect(device.frame.maxY <= folded.canvas.height, "\(orientation)")
            #expect(device.frame.minY >= folded.captionBox.maxY, "Under the caption, \(orientation)")
            #expect(abs(Self.aspect(folded.screen) - ScreenshotLayoutEngine.coverAspect) < 0.01)
        }
        var iPhone = ScreenshotsSampleData.template
        iPhone.device.bleed = 0.3
        iPhone.device.width = 1
        let phone = engine.layout(
            iPhone, slot: 0, locale: .englishUS, displayType: .iPhone, caption: ScreenshotsTestFixtures.caption("en-US", slot: 0),
            captureSize: ScreenshotDisplayType.iPhone.portraitPixelSize
        )
        #expect(try #require(phone.device).frame.maxY > phone.canvas.height, "An iPhone still bleeds as the template says")
    }

    /// Apple's cover-display mask (the iPhone Duo simulator's) is square
    /// on the hinge side and round on the side it opens from: the folded
    /// phone has its spine on the left, alone or beside the unfolded one,
    /// in either direction (the capture is never mirrored).
    @Test func theFoldedPhoneHasItsHingeOnTheLeft() throws {
        let folded = layout(captureSize: Self.cover)
        let device = try #require(folded.device)
        let spine = try #require(device.spine)
        #expect(spine.screenCornerRadius < folded.screenCornerRadius / 5, "Nearly square on the hinge side")
        #expect(spine.bodyCornerRadius < device.cornerRadius / 2)
        #expect(spine.overhang > 0 && spine.overhang < spine.width)

        #expect(layout(captureSize: Self.inner).device?.spine == nil, "The unfolded Duo has none")
        var landscape = ScreenshotsSampleData.template
        landscape.canvas.duo = .landscape
        landscape.rightToLeft.mirror = true
        let pair = layout(captureSize: Self.inner.rotated, companion: Self.cover, template: landscape)
        #expect(pair.device?.spine == nil)
        #expect(pair.companion?.device?.spine != nil)
        let arabic = try #require(StoreLocaleCatalog.locale(code: "ar-SA"))
        #expect(layout(captureSize: Self.cover, template: landscape, locale: arabic).device?.spine != nil)

        let iPhone = engine.layout(
            ScreenshotsSampleData.template, slot: 0, locale: .englishUS, displayType: .iPhone, caption: nil,
            captureSize: ScreenshotDisplayType.iPhone.portraitPixelSize
        )
        #expect(iPhone.device?.spine == nil)
    }

    /// Changing the Duo's frame renders its screenshots again and counts
    /// them as changed; every other device keeps its keys, so what's live
    /// stays live.
    @Test func onlyTheDuosRenderKeysChange() {
        #expect(RenderKey.frameRevision(for: .iPhoneDuo) != nil)
        for display in ScreenshotDisplayType.allCases where display != .iPhoneDuo {
            #expect(RenderKey.frameRevision(for: display) == nil, "\(display)")
        }
    }

    @Test func sideBySideFramesBothDisplaysAtTheSameScale() throws {
        var landscape = ScreenshotsSampleData.template
        landscape.canvas.duo = .landscape
        let pair = layout(captureSize: Self.inner.rotated, companion: Self.cover, template: landscape)
        let companion = try #require(pair.companion)
        _ = try #require(companion.device)
        #expect(abs(Self.aspect(companion.screen) - ScreenshotLayoutEngine.coverAspect) < 0.01)
        #expect(abs(Self.aspect(pair.screen) - CGFloat(2007) / 2853) < 0.01, "The unfolded Duo takes the canvas's shape")
        #expect(abs(companion.screen.width / pair.screen.width - CGFloat(1398) / 2853) < 0.01, "A capture pixel is as big on both")
        #expect(!pair.screen.intersects(companion.screen))
        #expect(companion.screen.minX > pair.screen.maxX, "The folded one on the trailing side")
        #expect(pair.screen.minX >= 0 && companion.screen.maxX <= pair.canvas.width)
        #expect(max(pair.screen.maxY, companion.screen.maxY) <= pair.canvas.height, "Whole: a pair doesn't bleed")
        #expect(ScreenshotChecker.captureSizeCheck(capture(Self.inner.rotated), layout: pair) == nil)
    }

    @Test func sideBySideMirrorsInRightToLeft() throws {
        var mirrored = ScreenshotsSampleData.template
        mirrored.canvas.duo = .landscape
        mirrored.rightToLeft.mirror = true
        let arabic = try #require(StoreLocaleCatalog.locale(code: "ar-SA"))
        let pair = layout(captureSize: Self.inner.rotated, companion: Self.cover, template: mirrored, locale: arabic)
        let companion = try #require(pair.companion)
        #expect(companion.screen.maxX < pair.screen.minX, "The folded one on the leading side")
    }

    @Test func aCompanionIsOnlyForTheInnerDisplay() {
        #expect(layout(captureSize: Self.cover, companion: Self.cover).companion == nil, "A folded screenshot has no pair")
        let iPhone = engine.layout(
            ScreenshotsSampleData.template, slot: 0, locale: .englishUS, displayType: .iPhone,
            caption: nil, captureSize: ScreenshotDisplayType.iPhone.portraitPixelSize, companionSize: Self.cover
        )
        #expect(iPhone.companion == nil)
    }

    @Test func aCaptureTellsItsPose() {
        #expect(AutopilotDuoPose(captureSize: Self.cover) == .closed)
        #expect(AutopilotDuoPose(captureSize: Self.inner.rotated) == .open)
        #expect(AutopilotDuoPose(captureSize: PixelSize(width: 1320, height: 2868)) == nil)
        #expect(AutopilotDuoPose.closed.launchLine(locale: "de-DE").hasPrefix("iPhone Duo folded · launch on the cover display -AppleLanguages (de)"))
        #expect(AutopilotDuoPose.open.launchLine(locale: "en-US")
            .hasPrefix("iPhone Duo opened in Device Hub · launch on the inner display -AppleLanguages (en-US)"))
    }
}
