//
//  ArtworkStoreNamesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The header and search write the app's name as each language's App
/// Store page has it ("Lumen: Tagebuch" in German), never the primary
/// language's in every image: the run keeps the names the Studio and the
/// design brief read, and every render, preview and thumbnail uses them.
@MainActor
@Suite("Artwork · the app's name in each language", .serialized)
struct ArtworkStoreNamesTests {
    private static let names = ["en-US": "Lumen: Journal", "de-DE": "Lumen: Tagebuch"]

    private static var run: AutopilotRun {
        var run = AutopilotTestFixtures.run(.localize)
        run.storeNames = names
        return run
    }

    // MARK: - The run's names

    @Test func eachLanguageHasItsPagesName() {
        let run = Self.run
        #expect(run.appName(in: "de-DE", fallback: "Lumen Journal") == "Lumen: Tagebuch")
        #expect(run.appName(in: "en-US", fallback: "Lumen Journal") == "Lumen: Journal")
        #expect(run.appName(in: "fr-FR", fallback: "Lumen Journal") == "Lumen: Journal", "A language without a page: the primary one's")
    }

    @Test func beforeThePageIsReadItsTheAccountsName() {
        var run = AutopilotTestFixtures.run(.localize)
        #expect(run.appName(in: "de-DE", fallback: "Lumen Journal") == "Lumen Journal")
        run.storeNames = ["de-DE": "  ", "en-US": ""]
        #expect(run.appName(in: "de-DE", fallback: "Lumen Journal") == "Lumen Journal", "Blank names don't count")
    }

    @Test func theCenterKeepsTheNamesOnTheRun() throws {
        let center = AutopilotTestFixtures.center()
        center.noteStoreNames(Self.names, appID: AutopilotTestFixtures.appID)
        #expect(center.run(for: AutopilotTestFixtures.appID) == nil, "Nothing without a run")

        center.install(AutopilotTestFixtures.run(.design))
        center.noteStoreNames(["en-US": " Lumen: Journal ", "de-DE": "Lumen: Tagebuch", "fr-FR": ""], appID: AutopilotTestFixtures.appID)
        #expect(center.run(for: AutopilotTestFixtures.appID)?.storeNames == Self.names, "Trimmed, without the blank ones")

        center.noteStoreNames(["de-DE": "Lumen: Logbuch"], appID: AutopilotTestFixtures.appID)
        let names = try #require(center.run(for: AutopilotTestFixtures.appID)?.storeNames)
        #expect(names == ["en-US": "Lumen: Journal", "de-DE": "Lumen: Logbuch"], "A page read for some languages keeps the others")
    }

    // MARK: - What's rendered

    @Test func aPageInGermanGetsTheGermanName() async throws {
        let services = AutopilotTestFixtures.services(AutopilotTestFixtures.center())
        let pages = AutopilotArtworkPages(context: AutopilotTestFixtures.context(services))
        let german = try #require(StoreLocaleCatalog.locale(code: "de-DE"))
        let request = await pages.request(
            html: ArtworkWebFixtures.searchPage(), kind: .search, locale: german, headline: "Tagebuch", run: Self.run, icon: nil, withCaptures: false
        )
        #expect(request.appName == "Lumen: Tagebuch")

        let measure = try await ArtworkWebRenderer(width: 1).measure(request)
        #expect(measure.elements(.appName).first?.text == "Lumen: Tagebuch", "The page shows it")

        let unread = await pages.request(
            html: ArtworkWebFixtures.searchPage(), kind: .search, locale: german, headline: "Tagebuch",
            run: AutopilotTestFixtures.run(.localize), icon: nil, withCaptures: false
        )
        #expect(unread.appName == AutopilotTestFixtures.app.name, "Before the page is read, the account's")
    }

    // MARK: - The Studio

    @Test func theStudiosStoreTextsGoOnTheRun() async {
        let center = AutopilotTestFixtures.center()
        center.install(AutopilotTestFixtures.run(.localize))
        let model = await StudioTestFixtures.screenshots(center: center)
        #expect(model.studio.appName(in: "de-DE") == model.studio.app.name, "Before the store page loads")

        model.studio.storeTexts = StudioStoreTexts(content: StorePageContentFixtures.editable)
        #expect(center.run(for: AutopilotTestFixtures.appID)?.storeNames == Self.names)
        #expect(model.studio.appName(in: "de-DE") == "Lumen: Tagebuch")
        #expect(model.studio.appName(in: "ja") == "Lumen: Journal", "A language without a page: the primary one's")
    }

    // MARK: - The design brief

    @Test func theBriefsNamesGoOnTheRun() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugExtras.run(.design))
        let brief = try await fixtures.call(GetDesignBriefTool(), ["run": "run-debug"]).result
        let languages = try #require(brief["aboutTheApp"]?["languages"]?.arrayValue)
        var expected: [String: String] = [:]
        for language in languages {
            if let locale = language["locale"]?.stringValue, let name = language["name"]?.stringValue { expected[locale] = name }
        }
        #expect(!expected.isEmpty)
        #expect(fixtures.run?.storeNames == expected)
        let fill = brief["artworkDesign"]?["fillIns"]?["appName"]?.stringValue ?? ""
        #expect(fill.contains("as each language's App Store page has it"), "Claude Design knows the name changes by language")
    }
}
#endif
