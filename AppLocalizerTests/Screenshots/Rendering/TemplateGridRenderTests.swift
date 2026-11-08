//
//  TemplateGridRenderTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Renders every gallery template on iPhone, iPad, iPhone Duo and Mac, in
/// English, German, Arabic and Japanese, with Lumen's mock captures,
/// captions, ratings and reviews, as one contact sheet per template and
/// device, to compare with the design canvas's Templates board. Runs only
/// when `GRID_OUT` is set (`TEST_RUNNER_GRID_OUT=1 xcodebuild
/// test-without-building …`), as attachments of the result bundle, since
/// the test host is sandboxed (`xcresulttool export attachments`); every
/// other run skips it. `GRID_ONLY` names the templates (`proof,arcade`),
/// `GRID_LOCALES` the locales (`en-US,de-DE`), `GRID_DISPLAYS` the display
/// types (`APP_DESKTOP`) and `GRID_WIDTH` each tile's width in pixels.
@MainActor
@Suite("Template grid render", .enabled(if: ProcessInfo.processInfo.environment["GRID_OUT"] != nil))
struct TemplateGridRenderTests {
    private static let locales: [StoreLocale] = [.englishUS, .german, .arabic, .japanese]
    private static let displays: [ScreenshotDisplayType] = [.iPhone, .iPad, .iPhoneDuo, .mac]
    /// The design's kicker lines (slots 3–5).
    private static let kickers: [String: [String]] = [
        "en-US": ["", "", "Find anything", "Your memories", "Private by design"],
        "de-DE": ["", "", "Alles finden", "Deine Erinnerungen", "Privat ab Werk"],
        "ja": ["", "", "すぐに見つかる", "あなたの思い出", "プライバシー重視"],
        "ar-SA": ["", "", "اعثر على أي شيء", "ذكرياتك", "خصوصية في التصميم"],
    ]

    @Test func renderTheGrid() throws {
        let countries = Set(Self.locales.map(\.regionCode) + ["US"])
        let engine = ScreenshotLayoutEngine(
            catalog: ScreenshotFontCatalog(), ratings: DebugStoreProof.storeRatings(countries: countries),
            reviews: DebugStoreProof.storeReviews(countries: countries)
        )
        let mock = MockLumenCaptureRenderer()
        let only = Self.list("GRID_ONLY")
        let locales = Self.locales.filter { Self.list("GRID_LOCALES")?.contains($0.code) ?? true }
        let displays = Self.displays.filter { Self.list("GRID_DISPLAYS")?.contains($0.rawValue) ?? true }
        let width = ProcessInfo.processInfo.environment["GRID_WIDTH"].flatMap(Int.init) ?? 360
        for starter in TemplateStarter.allCases where only?.contains(starter.rawValue) ?? true {
            let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
            for display in displays {
                var rows: [[CGImage]] = []
                for locale in locales {
                    var row: [CGImage] = []
                    for slot in 0..<5 {
                        let caption = Self.caption(locale: locale.code, slot: slot)
                        let probe = engine.layout(template, slot: slot, locale: locale, displayType: display, caption: caption)
                        let size = Self.captureSize(display: display, canvas: probe.canvas)
                        let capture = Self.capture(locale: locale.code, display: display, slot: slot, size: size)
                        let behind = template.behindSlot(slot, templateSlot: slot, count: 5).map {
                            Self.capture(locale: locale.code, display: display, slot: $0, size: size)
                        }
                        let layout = engine.layout(
                            template, slot: slot, locale: locale, displayType: display, caption: caption, captureSize: size
                        )
                        let image = ScreenshotImageRenderer.image(
                            layout: layout, capture: mock.image(for: capture, pixelWidth: 900),
                            companion: behind.flatMap { mock.image(for: $0, pixelWidth: 900) }, pixelWidth: width
                        )
                        if let image { row.append(image) }
                    }
                    rows.append(row)
                }
                let sheet = try #require(Self.sheet(rows))
                let data = try #require(ScreenshotPNG.data(sheet))
                Attachment.record(data, named: "\(starter.rawValue)-\(display.rawValue).png")
            }
        }
    }

    private static func list(_ name: String) -> Set<String>? {
        ProcessInfo.processInfo.environment[name].map { Set($0.split(separator: ",").map(String.init)) }
    }

    private static func caption(locale: String, slot: Int) -> ScreenshotCaption {
        let texts = ScreenshotsSampleData.captionTexts[locale] ?? ScreenshotsSampleData.captionTexts["en-US"] ?? []
        let parts = texts[slot % texts.count].split(separator: "|").map(String.init)
        let kicker = kickers[locale]?[slot] ?? ""
        return ScreenshotCaption(headline: parts[0], subhead: parts.count > 1 ? parts[1] : nil, kicker: kicker.isEmpty ? nil : kicker)
    }

    /// Mac: the whole screen; iPhone Duo: the inner display standing up;
    /// otherwise the canvas's own shape.
    private static func captureSize(display: ScreenshotDisplayType, canvas: ScreenshotCanvas) -> PixelSize {
        switch display {
        case .mac: PixelSize(width: 2880, height: 1800)
        case .iPhoneDuo: PixelSize(width: 2007, height: 2853)
        default: canvas.pixelSize
        }
    }

    private static func capture(locale: String, display: ScreenshotDisplayType, slot: Int, size: PixelSize) -> ScreenshotCapture {
        ScreenshotCapture(
            id: "\(locale)-\(display.rawValue)-\(slot)-\(size.width)", locale: locale, displayType: display, slot: slot, source: .folder,
            fileName: "\(locale)/\(display.rawValue)-0\(slot + 1).png", pixelSize: size
        )
    }

    /// The renders in rows, 12 px apart on grey.
    private static func sheet(_ rows: [[CGImage]]) -> CGImage? {
        let gap = 12
        let tileWidth = rows.flatMap(\.self).map(\.width).max() ?? 1
        let tileHeight = rows.flatMap(\.self).map(\.height).max() ?? 1
        let columns = rows.map(\.count).max() ?? 1
        let width = columns * tileWidth + (columns + 1) * gap
        let height = rows.count * tileHeight + (rows.count + 1) * gap
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(gray: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        for (rowIndex, row) in rows.enumerated() {
            for (column, image) in row.enumerated() {
                let x = gap + column * (tileWidth + gap)
                let y = height - (gap + rowIndex * (tileHeight + gap)) - image.height
                context.draw(image, in: CGRect(x: x, y: y, width: image.width, height: image.height))
            }
        }
        return context.makeImage()
    }
}
#endif
