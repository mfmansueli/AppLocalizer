//
//  ScreenshotsDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Every Screenshots scene id (one per design screenshot) opens a view.
@MainActor
@Suite("ScreenshotsDebugScenes")
struct ScreenshotsDebugScenesTests {
    @Test(arguments: ScreenshotsDebugScenes.ids)
    func everySceneHasAView(id: String) {
        #expect(ScreenshotsDebugScenes.view(for: id) != nil)
    }

    @Test func unknownIDsAreLeftToOtherSections() {
        #expect(ScreenshotsDebugScenes.view(for: "store-coverage") == nil)
    }

    @Test func idsAreUnique() {
        #expect(Set(ScreenshotsDebugScenes.ids).count == ScreenshotsDebugScenes.ids.count)
    }

    @Test func theDebugServicesServeEachScenario() async throws {
        let app = ScreenshotsTestFixtures.app
        let lumen = StoreApp(id: DebugFixtures.AppID.lumen, name: app.name, bundleID: app.bundleID, sku: nil, primaryLocale: "en-US")
        let other = StoreApp(id: "9999999999", name: "Quiet Timer", bundleID: "dev.example.quiet", sku: nil, primaryLocale: "en-US")
        let standard = try await DebugScreenshotsServices().document(for: lumen, primaryLocale: .englishUS)
        #expect(standard.scope.count == 12)
        let empty = try await DebugScreenshotsServices(scenario: .noCaptures).document(for: lumen, primaryLocale: .englishUS)
        #expect(empty.captures.isEmpty)
        let otherDocument = try await DebugScreenshotsServices().document(for: other, primaryLocale: .englishUS)
        #expect(otherDocument.template == nil)
    }

    @Test func theGlyphSceneTriesTheBrandFontWithoutSavingIt() {
        let document = ScreenshotsDebugDocuments.thaiAndVietnamese
        #expect(document.scope.count == 14)
        #expect(document.history?.currentNumber == 4)
        #expect(ScreenshotsDebugDocuments.failedChecks.history?.currentNumber == 5)
    }

    @Test func theDebugTranslatorAnswersWithTheSampleCaptions() async throws {
        let translator = DebugCaptionTranslator(delay: .zero)
        let polish = try #require(StoreLocaleCatalog.locale(code: "pl"))
        let german = try #require(StoreLocaleCatalog.locale(code: "de-DE"))
        let headline = try await translator.translateCaption("Search years of entries in seconds", from: .englishUS, to: polish)
        #expect(headline == ScreenshotsSampleData.captionTexts["pl"]?[2])
        let shorter = try await translator.translateCaption("Search years of entries in seconds", from: .englishUS, to: german)
        #expect(shorter == "Einträge aus Jahren in Sekunden finden")
        await #expect(throws: DebugCaptionTranslator.TranslationError.self) {
            try await translator.translateCaption("Not a sample caption", from: .englishUS, to: polish)
        }
    }
}
#endif
