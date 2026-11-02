//
//  CaptureViewerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A capture clicked in the Captures tab, shown large: what it says about
/// the capture, ← → through the locale's screens, ↑ ↓ through the locales,
/// wrapping around and skipping missing captures.
@MainActor
@Suite("Capture viewer")
struct CaptureViewerTests {
    private static func coverage(_ document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard) -> CaptureCoverage {
        CaptureCoverage.make(CaptureCoverage.Inputs(document: document, displayType: .iPhone, primary: .englishUS, locales: StoreLocaleCatalog.all))
    }

    /// English (U.S.) without its Photos capture: the locales that show
    /// English's captures have nothing there either.
    private static var withoutEnglishPhotos: ScreenshotsDocument {
        var document = ScreenshotsDebugDocuments.standard
        document.captures = CaptureIndex(captures: document.captures.captures.filter { !($0.locale == "en-US" && $0.slot == 3) })
        return document
    }

    private static func target(_ locale: String, _ slot: Int) -> CaptureViewerTarget {
        CaptureViewerTarget(localeCode: locale, slot: slot)
    }

    @Test func itSaysWhichCaptureItIsAndWhereItCameFrom() throws {
        let coverage = Self.coverage()
        let german = Self.target("de-DE", 1)
        #expect(coverage.viewerTitle(of: german) == "German · 2 Week")
        let capture = try #require(coverage.cell(for: german)?.capture)
        #expect(coverage.viewerSubtitle(of: german, display: .iPhone)
            == "iPhone 6.9″ · \(capture.pixelSize.title) px · fastlane snapshot · de-DE/iPhone 17 Pro Max-02_Week.png")
        #expect(coverage.viewerStatus(of: german, display: .iPhone) == "Localized · the interface is German")
        #expect(coverage.viewerStatus(of: Self.target("nl-NL", 1), display: .iPhone) == "English (U.S.) capture used, interface not localized")
    }

    @Test func aWrongSizeCaptureSaysWhyItIsntUsed() throws {
        let coverage = Self.coverage(ScreenshotsDebugDocuments.thaiAndVietnamese)
        let korean = Self.target("ko", 3)
        let capture = try #require(coverage.cell(for: korean)?.capture)
        #expect(coverage.viewerStatus(of: korean, display: .iPhone)
            == "Wrong size · \(capture.pixelSize.title) doesn’t fit iPhone 6.9″ screenshots, so it isn’t used")
    }

    @Test func leftAndRightStepThroughTheLocalesScreens() {
        let coverage = Self.coverage()
        #expect(coverage.target(from: Self.target("de-DE", 0), screens: 1) == Self.target("de-DE", 1))
        #expect(coverage.target(from: Self.target("de-DE", 4), screens: 1) == Self.target("de-DE", 0))
        #expect(coverage.target(from: Self.target("de-DE", 0), screens: -1) == Self.target("de-DE", 4))
        #expect(coverage.screenPosition(of: Self.target("de-DE", 1)) == "Screen 2 of 5")
    }

    @Test func upAndDownStepThroughTheLocalesOnTheSameScreen() throws {
        let coverage = Self.coverage()
        let codes = coverage.allRows.map(\.locale.code)
        let last = try #require(codes.last)
        #expect(coverage.target(from: Self.target("en-US", 2), locales: 1) == Self.target("ar-SA", 2))
        #expect(coverage.target(from: Self.target("en-US", 2), locales: -1) == Self.target(last, 2))
        #expect(coverage.target(from: Self.target(last, 2), locales: 1) == Self.target("en-US", 2))
        #expect(coverage.localePosition(of: Self.target("en-US", 2)) == "Locale 1 of \(codes.count)")
    }

    @Test func missingCapturesAreSkipped() throws {
        let coverage = Self.coverage(Self.withoutEnglishPhotos)
        #expect(coverage.cell(for: Self.target("nl-NL", 3)) == nil)
        #expect(coverage.target(from: Self.target("nl-NL", 2), screens: 1) == Self.target("nl-NL", 4))
        #expect(coverage.screenPosition(of: Self.target("nl-NL", 4)) == "Screen 4 of 4")

        // On Photos, only the locales with a capture of their own.
        let photos = coverage.allRows.filter { $0.cells[3].capture != nil }.map(\.locale.code)
        #expect(!photos.contains("en-US") && !photos.contains("nl-NL") && photos.contains("de-DE"))
        let german = try #require(photos.firstIndex(of: "de-DE"))
        #expect(coverage.localePosition(of: Self.target("de-DE", 3)) == "Locale \(german + 1) of \(photos.count)")
        #expect(coverage.target(from: Self.target("de-DE", 3), locales: 1) == Self.target(photos[(german + 1) % photos.count], 3))
    }

    @Test func aClickOpensTheCaptureAndTheArrowsMoveOn() async throws {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        let coverage = try #require(model.captures.coverage)
        let rows = coverage.allRows
        let index = try #require(rows.firstIndex { $0.locale.code == "de-DE" })
        model.captures.view(rows[index].cells[1], of: rows[index])
        #expect(model.captures.viewed == Self.target("de-DE", 1))
        model.captures.stepViewedScreen(by: 1)
        #expect(model.captures.viewed == Self.target("de-DE", 2))
        model.captures.stepViewedLocale(by: -1)
        #expect(model.captures.viewed == Self.target(rows[index - 1].locale.code, 2))
    }

    @Test func aMissingCaptureHasNothingToOpen() async throws {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(Self.withoutEnglishPhotos)
        let dutch = try #require(model.captures.coverage?.allRows.first { $0.locale.code == "nl-NL" })
        model.captures.view(dutch.cells[3], of: dutch)
        #expect(model.captures.viewed == nil)
    }

    @Test func itLoadsACaptureAtItsOwnWidthUpTo1600Pixels() {
        let phone = ScreenshotsSampleData.capture(locale: "en-US", display: .iPhone, slot: 0)
        #expect(CapturesViewModel.viewerPixelWidth(of: phone) == phone.pixelSize.width)
        #expect(CapturesViewModel.viewerPixelWidth(of: ScreenshotsSampleData.capture(locale: "en-US", display: .iPad, slot: 0)) == 1600)
    }
}
#endif
