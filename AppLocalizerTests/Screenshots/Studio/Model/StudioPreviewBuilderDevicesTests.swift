//
//  StudioPreviewBuilderDevicesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The App Store preview and the set card on Apple Watch and Apple Vision
/// Pro: what's live (two English watch screenshots, no Vision Pro), the new
/// set's own screens, and what search shows.
@MainActor
@Suite("Studio preview · Apple Watch and Apple Vision Pro")
struct StudioPreviewBuilderDevicesTests {
    private static let document = DebugEveryDevice.document

    private static func builder(
        _ display: ScreenshotDisplayType,
        locale: String = "en-US",
        choice: StudioSetChoice = .live,
        pushed: Set<String> = []
    ) -> StudioPreviewBuilder {
        let live = DebugEveryDevice.live
        var builder = StudioTestFixtures.builder(locale: locale, displayType: display, choice: choice)
        builder.live = live
        builder.matrix = ScreenshotMatrixBuilder().build(ScreenshotsTestFixtures.snapshot(document, live: live))
        builder.ownSlotNames = [
            .watch: (document.screens(on: .watch) ?? []).map(\.name),
            .visionPro: (document.screens(on: .visionPro) ?? []).map(\.name),
        ]
        builder.pushedChecksums = pushed
        return builder
    }

    // MARK: - Live

    @Test func theLiveWatchSetIsTwoEnglishCapturesUploadedByHand() {
        let preview = Self.builder(.watch).preview()
        #expect(preview.displayType == .watch)
        #expect(preview.shots.map(\.label) == ["1 · Mood check-in", "2 · Today’s prompt"])
        #expect(preview.shots.allSatisfy { $0.chip == nil })
        #expect(preview.note == "Live now · 2 English captures, uploaded by hand")
        #expect(preview.searchNote.hasPrefix("Apple Watch screenshots don’t show in search results"))
    }

    @Test func aWatchSetAppLocalizerPushedSaysSo() {
        let preview = Self.builder(.watch, pushed: ["watch-en-US-0", "watch-en-US-1"]).preview()
        #expect(preview.note == "Live now · 2 English captures, made with AppLocalizer")
    }

    @Test func anotherLanguageShowsTheEnglishWatchSet() {
        let preview = Self.builder(.watch, locale: "de-DE").preview()
        #expect(preview.shots.count == 2)
        #expect(preview.shots.allSatisfy { $0.chip == .fallback(language: "English") })
        #expect(preview.note == "Live now · German falls back to English (U.S.)")
    }

    @Test func withNoVisionProSetThePreviewSaysWhatsNeeded() {
        let preview = Self.builder(.visionPro).preview()
        #expect(preview.shots.isEmpty)
        #expect(preview.note == "Live now · no Apple Vision Pro screenshots")
        #expect(preview.emptyText == "No Apple Vision Pro screenshots yet. App Store Connect needs at least one before you can submit for visionOS.")
    }

    // MARK: - New

    @Test func theNewSetShowsEachDevicesOwnScreens() {
        let watch = Self.builder(.watch, choice: .new).preview()
        #expect(watch.shots.map(\.name) == ["Mood check-in", "Today’s prompt", "Week", "Watch face"])
        #expect(watch.shots.first?.pixelSize == PixelSize(width: 422, height: 514))

        let vision = Self.builder(.visionPro, choice: .new).preview()
        #expect(vision.shots.map(\.name) == ["Today", "Week", "Search"])
        #expect(vision.shots.first?.pixelSize == PixelSize(width: 3840, height: 2160))
        #expect(vision.shots.allSatisfy { $0.aspect < 1 }, "Apple Vision Pro is landscape")
    }

    @Test(arguments: [
        (ScreenshotDisplayType.watch, 0),
        (.visionPro, 1),
        (.iPhone, 3),
    ])
    func searchShowsFewerScreenshotsOnBiggerScreens(display: ScreenshotDisplayType, shots: Int) {
        #expect(Self.builder(display, choice: .new).preview().searchShots.count == shots)
    }

    // MARK: - Set card

    @Test func theLiveCardHasALineForEachDeviceTheAppRunsOn() {
        let summary = StudioSetSummaryBuilder(
            preview: Self.builder(.iPhone), templateVersion: 4, captureCount: 30, devices: ScreenshotDisplayType.studio
        ).summary()
        #expect(summary.lines.map(\.label) == ["Made", "Languages", "iPad", "Apple Watch", "Apple Vision Pro", "Screenshots"])
        #expect(summary.lines.first { $0.label == "Apple Watch" }?.value == "2 English captures")
        #expect(summary.lines.first { $0.label == "Apple Vision Pro" }?.value == "None yet")

        let phoneOnly = StudioSetSummaryBuilder(preview: Self.builder(.iPhone), templateVersion: 4, captureCount: 30).summary()
        #expect(phoneOnly.lines.map(\.label) == ["Made", "Languages", "iPad", "Screenshots"])
    }

    @Test func theNewCardNamesEveryDeviceInTheSet() throws {
        let summary = StudioSetSummaryBuilder(
            preview: Self.builder(.iPhone, choice: .new), templateVersion: 4, captureCount: 30, devices: ScreenshotDisplayType.studio
        ).summary()
        let screenshots = try #require(summary.lines.first { $0.label == "Screenshots" }?.value)
        #expect(screenshots.contains(["iPhone", "iPad", "Apple Watch", "Apple Vision Pro"].formatted(.list(type: .and))))
    }
}
#endif
