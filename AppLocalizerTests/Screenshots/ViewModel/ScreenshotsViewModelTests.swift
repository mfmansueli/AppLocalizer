//
//  ScreenshotsViewModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Screenshots view's bar, banner and groups on the sample documents.
@MainActor
@Suite("ScreenshotsViewModel")
struct ScreenshotsViewModelTests {
    @Test func theBarSaysWhatTheDesignSays() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(model.scopeTitle == "12 of 39 locales localized")
        #expect(model.statusText == "40 not pushed · 2 checks failed · both display types")
        #expect(model.overflowingCaptions == 1)
        #expect(model.showsThumbnailSizes)
    }

    @Test func theBannerNamesTheFirstFailure() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        guard case let .failedChecks(title, message, first) = model.banner else {
            Issue.record("Expected the failed checks banner")
            return
        }
        #expect(title == "2 renders fail their checks.")
        #expect(message == "First: German, slot 3 · Overflow. They stay out of Review & Push until they pass.")
        #expect(first.locale == "de-DE")
    }

    @Test func aLiveVersionShowsTheNoVersionBanner() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(version: ScreenshotsTestFixtures.liveVersion)
        guard case let .noVersion(title, message) = model.banner else {
            Issue.record("Expected the no-version banner")
            return
        }
        #expect(title == "No version to push to.")
        #expect(message.hasPrefix("Version 1.3 is live."))
        #expect(message.contains("create 1.4 in App Store Connect"))
    }

    @Test func theFailedDocumentCountsFourteenLocales() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(ScreenshotsDebugDocuments.failedChecks)
        #expect(model.scopeTitle == "14 of 39 locales localized")
        #expect(model.statusText == "117 not pushed · 23 checks failed · both display types")
    }

    @Test func groupsAreLocalizedThenTheCollapsedFallback() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(model.groups.map(\.kind) == [.localized, .fallback])
        #expect(model.groups.first?.rows.count == 12)
        #expect(model.groups.last?.rows.isEmpty == true)
        #expect(model.groups.last?.title == "Use English (U.S.) Screenshots")
        model.showsFallbackRows = true
        #expect(model.groups.last?.rows.count == 27)
    }

    @Test func slotsOneToThreeShowInSearchOnIPhone() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(model.slotTitles.map(\.name) == ["Today", "Week", "Search", "Photos", "Privacy"])
        #expect(model.showsInSearch(slot: 2))
        #expect(!model.showsInSearch(slot: 3))
        model.displayType = .iPad
        #expect(!model.showsInSearch(slot: 0))
    }

    @Test func thumbnailsFollowTheSizeAndDisplayType() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(model.thumbnailWidth == 64)
        #expect(model.thumbnailHeight == 139)
        model.thumbnailSize = .large
        model.displayType = .iPad
        #expect(model.thumbnailWidth == 164)
        #expect(model.thumbnailHeight == 123)
    }

    @Test func nothingImportedSaysSo() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(.empty(primary: "en-US"))
        #expect(!model.hasCaptures)
        #expect(model.statusText == "No captures yet")
        #expect(model.scopeTitle == "1 of 39 locales localized")
        #expect(model.groups.isEmpty)
    }

    @Test func choosingAStarterSavesVersionOne() async throws {
        let (model, services) = await ScreenshotsTestFixtures.viewModel(ScreenshotsDebugDocuments.document(for: .noTemplate))
        #expect(!model.hasTemplate)
        #expect(model.statusText == "No template yet")
        await model.chooseStarter(.band)
        let saved = try #require(services.saved.last)
        #expect(saved.template?.starter == .band)
        #expect(saved.history?.currentNumber == 1)
        #expect(model.hasTemplate)
    }

    @Test func nextVersionIsTheLastNumberPlusOne() {
        #expect(ScreenshotsViewModel.nextVersionString(after: "1.3") == "1.4")
        #expect(ScreenshotsViewModel.nextVersionString(after: "2.0.9") == "2.0.10")
        #expect(ScreenshotsViewModel.nextVersionString(after: "3") == "4.0")
    }

    @Test func theDisplayMenuListsWhatTemplatesDontRender() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(model.otherDisplayTypeNotes.map(\.0) == [.mac])
        #expect(model.pixelSize(for: .iPad) == PixelSize(width: 2752, height: 2064))
    }

    @Test func aFailedLoadKeepsTheMessage() async {
        let services = FakeScreenshotsServices()
        services.error = AppStoreConnectError.rateLimited
        let context = ScreenshotsContext(primaryLocale: .englishUS, version: ScreenshotsTestFixtures.editableVersion)
        let model = ScreenshotsViewModel(app: ScreenshotsTestFixtures.app, services: services, context: context)
        await model.load()
        #expect(!model.isLoaded)
        #expect(model.errorMessage != nil)
    }
}
#endif
