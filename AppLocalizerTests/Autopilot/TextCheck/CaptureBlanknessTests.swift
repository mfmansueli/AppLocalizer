//
//  CaptureBlanknessTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// How much of a capture is blank. MB Admin's iPad set had a nearly empty
/// sheet, and blank iPhone Duo frames passed the text check: a mostly
/// blank capture now comes back with a check, like cut-off text.
@MainActor
@Suite("Capture blankness")
struct CaptureBlanknessTests {
    private static let width = 240
    private static let height = 520

    /// Gray pixels, flat where `isFlat(row)` and noisy elsewhere.
    private static func pixels(isFlat: (Int) -> Bool) -> [UInt8] {
        var pixels = [UInt8](repeating: 242, count: width * height)
        for y in 0..<height where !isFlat(y) {
            for x in 0..<width { pixels[y * width + x] = UInt8((x * 37 + y * 11) % 200) }
        }
        return pixels
    }

    private static func share(_ pixels: [UInt8]) -> Double {
        CaptureBlankness.largestBlankShare(gray: pixels, width: width, height: height) ?? -1
    }

    @Test func aBlankScreenIsAllBlankAndAFullOneNone() {
        #expect(Self.share(Self.pixels { _ in true }) == 1)
        #expect(Self.share(Self.pixels { _ in false }) == 0)
    }

    @Test func aShortListWithSpaceBelowIsntMostlyBlank() {
        // Content down to 60% of the screen, then flat: as MB Admin's
        // accounts list with four rows.
        let share = Self.share(Self.pixels { $0 > Self.height * 6 / 10 })
        #expect(share > 0.3 && share < CaptureBlankness.mostlyBlank, "\(share)")
    }

    @Test func anAlmostEmptySheetIsMostlyBlank() {
        // A title near the top, then nothing.
        let share = Self.share(Self.pixels { $0 > Self.height / 5 })
        #expect(share >= CaptureBlankness.mostlyBlank, "\(share)")
    }

    @Test func theStatusBarDoesntCount() {
        // Only the status bar has anything in it.
        #expect(Self.share(Self.pixels { $0 > 20 }) == 1)
    }

    @Test func anImageIsMeasuredThroughCoreGraphics() throws {
        let context = try #require(CGContext(
            data: nil, width: 1320, height: 2868, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 1320, height: 2868))
        let black = try #require(context.makeImage())
        #expect(CaptureBlankness.largestBlankShare(of: black) == 1)
    }

    @Test func aMostlyBlankCaptureHasAnIssueInAnyLanguage() {
        var plan = AutopilotTestFixtures.smallPlan
        plan.localeCodes = ["en-US", "de-DE"]
        let run = AutopilotTestFixtures.run(.pick, plan: plan)
        func capture(_ locale: String, blank: Double) -> AutopilotCapture {
            AutopilotCapture(
                id: locale, target: AutopilotCaptureTarget(screenID: plan.screens[0].id, displayType: .iPhone, locale: locale),
                attempt: 1, score: 0.9, notes: "", captureID: "png", pixelSize: ScreenshotDisplayType.iPhone.portraitPixelSize,
                receivedAt: AutopilotTestFixtures.now, text: CaptureTextFacts(language: "en", blankShare: blank)
            )
        }
        #expect(run.textIssues(of: capture("en-US", blank: 0.77)) == [.mostlyBlank(percent: 77)])
        #expect(run.textIssues(of: capture("de-DE", blank: 0.6)).contains(.mostlyBlank(percent: 60)))
        #expect(run.textIssues(of: capture("en-US", blank: 0.4)).isEmpty, "A short list leaves space below it")
        #expect(CaptureTextIssue.mostlyBlank(percent: 77).message == "77% of the screen is blank: an empty state, or a screen still loading.")
        #expect(CaptureTextIssue.mostlyBlank(percent: 77).fix.contains("select the first item"))
    }

    @Test func theAnalyzerKeepsTheShare() {
        let reading = CaptureTextReading(lines: [], readsLanguage: true, blankShare: 0.7734)
        #expect(CaptureTextAnalyzer.facts(of: reading, appName: "MB Admin").blankShare == 0.77)
    }
}
#endif
