//
//  ScreenshotStudioPreviewReviewTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Watch the App Preview in the Studio: which App Preview plays, the info
/// box's lines, the quick asks and Ask, Approve, and the person's own
/// music file.
@MainActor
@Suite("ScreenshotStudioModel · watch the App Preview")
struct ScreenshotStudioPreviewReviewTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    /// Watching v1, with the run's App Previews saved with the set.
    private func watching(languages: AutopilotPreviewLanguages = .primary) async -> (ScreenshotsViewModel, AutopilotCenter) {
        var run = StudioDebugExtras.run(.watchPreview, languages: languages)
        run.plan.alsoMakes.makesArtwork = false
        run.previewReview = AutopilotPreviewReview()
        let center = StudioTestFixtures.center(run)
        var document = ScreenshotsDebugDocuments.standard
        document.extras = StudioDebugExtras.extras(for: run)
        return await (StudioTestFixtures.screenshots(center: center, document: document), center)
    }

    @Test func thePrimaryLanguagePlaysOnTheFirstDevice() async throws {
        let (model, _) = await watching()
        let studio = model.studio
        #expect(studio.watchLocales == ["en-US"])
        #expect(studio.watchDevices == [.iPhone, .iPad])
        let file = try #require(studio.watchedPreview)
        #expect(file.displayType == .iPhone)
        #expect(file.locale == "en-US")

        studio.watchedDevice = .iPad
        #expect(studio.watchedPreview?.displayType == .iPad)
        #expect(studio.previewSizesLine == "iPhone 886 × 1920 · iPad 1200 × 1600 · 30 fps")
    }

    @Test func everyLanguageWithItsOwnCanBeWatched() async {
        let (model, _) = await watching(languages: .all)
        let studio = model.studio
        #expect(studio.watchLocales.first == "en-US")
        #expect(studio.watchLocales.count == 12)
        studio.watchedLocale = "de-DE"
        #expect(studio.watchedPreview?.locale == "de-DE")
    }

    @Test func theInfoBoxSaysWhatPlaysWhen() async {
        let (model, _) = await watching()
        let studio = model.studio
        var file = ExtrasPreviewFile(
            displayType: .iPhone, locale: "en-US", recordedLocale: "en-US", fileID: "f", seconds: 24,
            pixelSize: PixelSize(width: 886, height: 1920), byteCount: 1, posterSeconds: 5
        )
        #expect(studio.previewLengthLine(file) == "0:24")
        #expect(studio.previewPosterLine(file) == "0:05")
        file.scenes = [
            ExtrasPreviewScene(screenID: "today", title: "Today", start: 0, duration: 7),
            ExtrasPreviewScene(screenID: "week", title: "Week", start: 7, duration: 14),
            ExtrasPreviewScene(screenID: nil, title: "End card", start: 21, duration: 3),
        ]
        #expect(studio.previewLengthLine(file) == "0:24 · Today, Week, end card")
        #expect(studio.previewPosterLine(file) == "0:05 · the Today screen")
        file.posterSeconds = 22
        #expect(studio.previewPosterLine(file) == "0:22 · the end card")
        #expect(studio.previewChecksLine(file) == "Fits Apple’s rules: 15–30 s, 30 fps, stereo, under 500 MB")
        file.problems = ["It’s 32 s; Apple takes 15–30 s."]
        #expect(studio.previewChecksLine(file) == "It’s 32 s; Apple takes 15–30 s.")
    }

    @Test func quickAsksAddUpAndAskSendsThemToClaudeDesign() async throws {
        let (model, center) = await watching()
        let studio = model.studio
        studio.addPreviewAsk("Slower pace")
        studio.addPreviewAsk("Start with Search")
        #expect(studio.previewNote == "Slower pace, start with search")

        studio.askForPreviewChanges()
        #expect(studio.previewNote.isEmpty)
        let review = try #require(center.run(for: appID)?.previewReview)
        #expect(review.request?.note == "Slower pace, start with search")
        #expect(review.isBusy)
    }

    @Test func approvingGoesOnToReviewAndPush() async {
        let (model, center) = await watching()
        model.studio.viewedStep = .localize
        model.studio.approvePreview()
        #expect(center.run(for: appID)?.stage == .ready)
        #expect(model.studio.viewedStep == nil)
    }

    @Test func aSilentMusicFileIsTurnedAwayPlainly() async throws {
        let (model, center) = await watching()
        let url = AppPreviewTestRecording.temporaryURL("music.m4a")
        try Data("Not music".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        await model.studio.useMusicFile(url)
        #expect(model.studio.musicError == AppPreviewError.unreadableMusic.errorDescription)
        #expect(center.run(for: appID)?.plan.alsoMakes.previewMusic == .standard)
    }

    @Test func theSetsMusicIsShownUntilThePlanHasOne() async {
        let (model, _) = await watching()
        #expect(model.studio.previewMusic == .standard)
        #expect(ScreenshotStudioModel.previewQuickAsks == ["Slower pace", "Start with Search", "Bigger captions", "Calmer music"])
    }
}
#endif
