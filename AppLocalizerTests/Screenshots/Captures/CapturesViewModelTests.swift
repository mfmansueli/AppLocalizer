//
//  CapturesViewModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("CapturesViewModel")
struct CapturesViewModelTests {
    /// The design's first import: a five-slot template, no captures yet.
    private func emptyModel(template: Bool = true) async -> (ScreenshotsViewModel, FakeScreenshotsServices) {
        var document = ScreenshotsDocument.empty(primary: "en-US")
        if template { document.history = ScreenshotsSampleData.history }
        return await ScreenshotsTestFixtures.viewModel(document)
    }

    @Test func theMatchingStepShowsTheRowsThatNeedYouAndTheFirstMatched() async {
        let (model, _) = await emptyModel()
        model.captures.present(ScreenshotsSampleData.fastlaneScan)
        #expect(model.tab == .captures)
        let rows = model.captures.visibleRows
        #expect(rows.count(where: \.needsYou) == 3)
        #expect(rows.count { !$0.needsYou } == CapturesViewModel.matchedPreviewCount)
        #expect(model.captures.moreMatchedText == "+ 45 more matched files")
        model.captures.showsAllMatched = true
        #expect(model.captures.visibleRows.count == 55)
        #expect(model.captures.moreMatchedText == nil)
    }

    @Test func withoutATemplateAnySlotUpToTenIsFine() async {
        let (model, _) = await emptyModel(template: false)
        model.captures.present(ScreenshotsSampleData.fastlaneScan)
        #expect(model.captures.session?.needsYouCount == 2)
        #expect(model.captures.session?.rows.contains { $0.path.contains("-06_") && !$0.needsYou } == true)
    }

    @Test func theFirstImportSetsTheScopeToTheCapturedLocales() async throws {
        let (model, services) = await emptyModel()
        model.captures.present(ScreenshotsSampleData.fastlaneScan)
        let portuguese = try #require(model.captures.session?.rows.first { $0.path.hasPrefix("pt/") })
        model.captures.choose(.skip, forRow: portuguese.id)
        await model.captures.importCaptures()

        let document = try #require(services.storedDocument)
        #expect(document.captures.captures.count == 52)
        #expect(document.scope.count == 10)
        #expect(document.scope.contains("nl-NL"))
        #expect(document.slotNames == ["Today", "Week", "Search", "Photos", "Privacy"])
        #expect(document.captures.captures.allSatisfy { $0.importedAt != nil && $0.source == .fastlane })
        #expect(model.captures.session == nil)
        #expect(model.tab == .sets)
        #expect(model.notice == "52 captures imported for 10 locales. The other 29 locales will show English (U.S.) screenshots unless you add them.")
    }

    @Test func aLaterImportKeepsTheScope() async throws {
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        let before = try #require(model.document?.scope)
        let scan = CaptureScan(source: .folder, location: "~/Captures", candidates: [
            CaptureCandidate(
                path: "fi/01-Today.png", origin: .file(URL(filePath: "/fi/01-Today.png")), source: .folder,
                pixelSize: ScreenshotDisplayType.iPhone.portraitPixelSize, localeCode: "fi", slotNumber: 1, slotName: "Today"
            ),
        ])
        model.captures.present(scan)
        model.tab = .captures
        await model.captures.importCaptures()
        #expect(services.storedDocument?.scope == before)
        #expect(services.storedDocument?.captures.ownCapture(locale: "fi", displayType: .iPhone, slot: 0) != nil)
        #expect(model.notice == "1 capture imported for 1 locale.")
        #expect(model.tab == .captures)
    }

    @Test func addingASlotSavesATemplateVersion() async throws {
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        model.captures.present(ScreenshotsSampleData.fastlaneScan)
        let extra = try #require(model.captures.session?.rows.first { $0.path.contains("-06_") })
        model.captures.choose(.addSlot(6), forRow: extra.id)
        await model.captures.importCaptures()
        let document = try #require(services.storedDocument)
        #expect(document.template?.slots.count == 6)
        #expect(document.history?.currentNumber == 5)
        #expect(document.history?.current?.note == "Added slot 6 for imported captures")
        #expect(document.slotName(5) == "Settings")
    }

    @Test func cancelLeavesTheDocumentAlone() async {
        let (model, services) = await emptyModel()
        model.captures.present(ScreenshotsSampleData.fastlaneScan)
        model.captures.cancel()
        #expect(model.captures.session == nil)
        #expect(services.saved.isEmpty)
    }

    @Test func liveScreenshotsNeedASetToImport() async {
        let (model, _) = await emptyModel()
        model.captures.useLiveScreenshots()
        #expect(model.captures.session?.source == .appStoreConnect)
        #expect(model.captures.session?.warning != nil)

        let (bare, services) = await emptyModel()
        services.live = LiveScreenshots()
        await bare.load()
        bare.captures.useLiveScreenshots()
        #expect(bare.captures.session == nil)
        #expect(bare.captures.errorMessage != nil)
    }

    @Test func coverageFollowsTheDisplayType() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(model.captures.coverage?.summary.hasSuffix("iPhone interface") == true)
        model.displayType = .iPad
        model.renderQueue.cancel()
        #expect(model.captures.coverage?.summary.hasSuffix("iPad interface") == true)
        let (empty, _) = await emptyModel()
        #expect(empty.captures.coverage == nil)
    }
}
