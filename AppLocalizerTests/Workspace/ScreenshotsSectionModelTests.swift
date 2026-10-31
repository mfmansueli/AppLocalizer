//
//  ScreenshotsSectionModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Screenshots section (⌘4): it reads the version Store Page would
/// show, makes the screenshots model once on the tab the services ask for,
/// and gives the preview the version's names and subtitles.
@MainActor
@Suite("ScreenshotsSectionModel")
struct ScreenshotsSectionModelTests {
    @Test func loadingMakesTheScreenshotsModelOnTheEditableVersion() async throws {
        let services = FakeStorePageServices()
        let section = ScreenshotsSectionModel(app: StorePageContentFixtures.app, services: services)
        await section.load()
        let screenshots = try #require(section.screenshots)
        #expect(section.content?.version.id == "v2")
        #expect(section.errorMessage == nil)
        #expect(!section.isLoading)
        #expect(screenshots.context.version.versionString == "2.0")
        #expect(screenshots.context.primaryLocale == .englishUS)
        #expect(services.contentRequests == [nil])
    }

    @Test(arguments: [ScreenshotsTab.preview, .sets, .captions])
    func theSectionOpensOnTheServicesTab(tab: ScreenshotsTab) async {
        let services = FakeStorePageServices()
        services.screenshots = StudioTestServices(initialTab: tab)
        let section = ScreenshotsSectionModel(app: StorePageContentFixtures.app, services: services)
        await section.load()
        #expect(section.screenshots?.tab == tab)
    }

    @Test func servicesWithoutAPreferenceOpenOnPreview() async {
        let section = ScreenshotsSectionModel(app: StorePageContentFixtures.app, services: FakeStorePageServices())
        await section.load()
        #expect(section.screenshots?.tab == .preview)
    }

    @Test func thePreviewGetsTheVersionsNamesAndSubtitles() async throws {
        let section = ScreenshotsSectionModel(app: StorePageContentFixtures.app, services: FakeStorePageServices())
        await section.load()
        let studio = try #require(section.screenshots?.studio)
        #expect(studio.storeTexts == StudioStoreTexts(content: StorePageContentFixtures.editable))
        #expect(studio.locales.map(\.code) == ["en-US", "de-DE"])
        #expect(studio.storeTexts.names["de-DE"] == "Lumen: Tagebuch")
    }

    @Test func loadingAgainKeepsTheModelAndRefreshesTheTexts() async throws {
        let services = FakeStorePageServices()
        let section = ScreenshotsSectionModel(app: StorePageContentFixtures.app, services: services)
        await section.load()
        let first = try #require(section.screenshots)
        first.tab = .template
        services.contents["v2"]?.texts[.german]?[.name] = "Lumen: Notizen"
        await section.load()
        #expect(section.screenshots === first)
        #expect(first.tab == .template)
        #expect(first.studio.storeTexts.names["de-DE"] == "Lumen: Notizen")
    }

    @Test func anotherVersionMovesTheSameModel() async throws {
        let services = FakeStorePageServices()
        let section = ScreenshotsSectionModel(app: StorePageContentFixtures.app, services: services)
        await section.load()
        let first = try #require(section.screenshots)
        services.defaultVersionID = "v19"
        await section.load()
        #expect(section.screenshots === first)
        #expect(first.context.version.id == "v19")
        #expect(!first.context.version.isEditable)
    }

    @Test func aFailureShowsItsMessageUntilALoadWorks() async {
        let services = FakeStorePageServices()
        services.error = URLError(.notConnectedToInternet)
        let section = ScreenshotsSectionModel(app: StorePageContentFixtures.app, services: services)
        await section.load()
        #expect(section.screenshots == nil)
        #expect(section.errorMessage == URLError(.notConnectedToInternet).localizedDescription)
        services.error = nil
        await section.load()
        #expect(section.errorMessage == nil)
        #expect(section.screenshots != nil)
    }
}
