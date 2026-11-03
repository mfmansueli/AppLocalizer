//
//  AppPreviewStylerTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The frame around the recording and the end card.
@Suite("App Preview styler")
struct AppPreviewStylerTests {
    private let template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
    private let iPhoneRecording = PixelSize(width: 1320, height: 2868)

    private func styler(
        _ template: ScreenshotTemplate? = nil, locale: StoreLocale = .englishUS, landscape: Bool = false, display: ScreenshotDisplayType = .iPhone,
        recording: PixelSize? = nil
    ) throws -> AppPreviewStyler {
        let spec = try #require(AppPreviewSpec.spec(for: display, landscape: landscape))
        return AppPreviewStyler(template: template ?? self.template, locale: locale, spec: spec, recordingSize: recording ?? iPhoneRecording)
    }

    @Test func framesAndTheEndCardAreExactlyTheSpecsSizeAndOpaque() throws {
        let styler = try styler()
        let frame = try styler.frame(headline: "Plan your week in seconds")
        let card = try styler.endCard(appName: "Lumen", headline: "Plan your week in seconds")
        for image in [frame, card] {
            #expect(image.width == 886)
            #expect(image.height == 1920)
            #expect(AppPreviewPixels.color(of: image, at: CGPoint(x: 0, y: 0))?.alpha == 1)
            #expect(AppPreviewPixels.color(of: image, at: CGPoint(x: 885, y: 1919))?.alpha == 1)
        }
    }

    @Test func theRecordingSitsBelowTheCaptionBandAtItsOwnShape() throws {
        let styler = try styler()
        let canvas = CGRect(x: 0, y: 0, width: 886, height: 1920)
        #expect(styler.captionRect.minY == 0)
        #expect(styler.appRect.minY >= styler.captionRect.maxY)
        #expect(canvas.contains(styler.appRect))
        let aspect = styler.appRect.width / styler.appRect.height
        #expect(abs(aspect - 1320.0 / 2868.0) < 0.01)
        #expect(styler.appCornerRadius > 0)
        #expect(styler.appCornerRadius < styler.appRect.width / 2)
    }

    @Test func aBelowCaptionGoesUnderTheRecording() throws {
        var below = template
        below.caption.placement = .below
        let styler = try styler(below)
        #expect(styler.captionRect.maxY == 1920)
        #expect(styler.appRect.maxY <= styler.captionRect.minY)
    }

    @Test func aBandTemplateFillsTheBandWithItsColor() throws {
        var band = template
        band.caption.placement = .band
        band.caption.band.pos = .top
        band.caption.band.color = "#E0306A"
        let frame = try styler(band).frame(headline: "Every task in one place")
        let pixel = AppPreviewPixels.color(of: frame, at: CGPoint(x: 6, y: 6))
        #expect(AppPreviewPixels.matches(pixel, TemplateColor(red: 0xE0 / 255, green: 0x30 / 255, blue: 0x6A / 255), tolerance: 0.02))
    }

    @Test func theScreenIsDarkUntilTheRecordingCovers() throws {
        let styler = try styler()
        let frame = try styler.frame(headline: "Plan your week")
        let center = CGPoint(x: styler.appRect.midX, y: styler.appRect.midY)
        #expect(AppPreviewPixels.matches(AppPreviewPixels.color(of: frame, at: center), AppPreviewStyler.screenColor, tolerance: 0.03))
    }

    @Test func aLandscapeIPadKeepsTheRecordingOnItsSide() throws {
        let styler = try styler(landscape: true, display: .iPad, recording: PixelSize(width: 2752, height: 2064))
        #expect(styler.spec.pixelSize == PixelSize(width: 1600, height: 1200))
        #expect(styler.appRect.width > styler.appRect.height)
        #expect(CGRect(x: 0, y: 0, width: 1600, height: 1200).contains(styler.appRect))
        #expect(styler.appRect.minY >= styler.captionRect.maxY)
        let frame = try styler.frame(headline: "Sketch on the big screen")
        #expect(frame.width == 1600)
        #expect(frame.height == 1200)
    }

    @Test func aLongGermanHeadlineFitsOnTwoLines() throws {
        let styler = try styler(locale: .german)
        let fit = styler.captionFit(for: "Alle Lieblingsrezepte immer griffbereit, auch ohne Internetverbindung")
        #expect(fit.fits)
        #expect((1...2).contains(fit.lines.count))
        #expect(fit.size <= Double(styler.captionSize))
    }

    @Test func anOverlongHeadlineDoesNotFit() throws {
        let styler = try styler()
        let words = Array(repeating: "Everything you need to plan, share and finish the week's work together", count: 4)
        #expect(!styler.captionFit(for: words.joined(separator: " ")).fits)
        #expect(styler.captionFit(for: "").isEmpty)
    }

    @Test func anUppercaseStyleUsesTheLanguagesOwnRules() throws {
        var upper = template
        upper.caption.headline.uppercase = true
        let fit = try styler(upper, locale: .german).captionFit(for: "Die große Straße")
        #expect(fit.lines.joined(separator: " ") == "DIE GROSSE STRASSE")
    }

    @Test func rightToLeftHeadlinesAreSet() throws {
        let styler = try styler(locale: .arabic)
        let fit = styler.captionFit(for: "خطط لأسبوعك في ثوانٍ")
        #expect(fit.fits)
        #expect(!fit.lines.isEmpty)
        let frame = try styler.frame(headline: "خطط لأسبوعك في ثوانٍ")
        #expect(frame.width == 886)
    }
}
