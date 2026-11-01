//
//  CaptureTextReaderTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import CoreText
import Foundation
import Testing
import Vision
@testable import AppLocalizer

/// Vision reading real text: a drawn German screen reads as German, and
/// each locale finds Vision's language for it.
@Suite("Capture text reader")
struct CaptureTextReaderTests {
    /// White, 1200 × 1600, with `lines` in black from an eighth of the way
    /// down, clear of the status bar.
    private static func image(_ lines: [String]) throws -> CGImage {
        let width = 1200
        let height = 1600
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let font = CTFontCreateWithName("Helvetica" as CFString, 48, nil)
        for (index, text) in lines.enumerated() {
            let attributed = NSAttributedString(string: text, attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(red: 0, green: 0, blue: 0, alpha: 1),
            ])
            context.textPosition = CGPoint(x: 60, y: CGFloat(height) - 200 - CGFloat(index) * 90)
            CTLineDraw(CTLineCreateWithAttributedString(attributed), context)
        }
        return try #require(context.makeImage())
    }

    @Test func aGermanScreenReadsAsGermanWithItsCutOffLabel() async throws {
        let image = try Self.image([
            "Diese Woche", "Ein langer Spaziergang am Fluss", "Abendessen mit Ana und Familie", "Schreibe jeden Tag ein wenig", "Einträge durchsu…",
        ])
        let reading = try #require(await CaptureTextReader.reading(of: image, language: "de", primary: "en-US"))
        #expect(reading.readsLanguage)
        #expect(reading.lines.contains { $0.text.contains("Spaziergang") }, "\(reading.lines.map(\.text))")
        #expect(reading.lines.allSatisfy { $0.top > 0.06 && $0.top < 1 })
        let facts = CaptureTextAnalyzer.facts(of: reading, appName: "Lumen")
        #expect(facts.language == "de")
        #expect(facts.truncatedLines.count == 1, "\(facts.truncatedLines)")
    }

    @Test func eachLanguageFindsVisionsOwn() throws {
        let supported = RecognizeTextRequest().supportedRecognitionLanguages
        let german = try #require(CaptureTextReader.match("de", in: supported))
        #expect(german.languageCode?.identifier == "de")
        let traditional = try #require(CaptureTextReader.match("zh-Hant", in: supported))
        #expect(CaptureTextLanguage.isSame(traditional.maximalIdentifier, "zh-Hant"))
        #expect(CaptureTextReader.match("xx", in: supported) == nil)
    }
}
