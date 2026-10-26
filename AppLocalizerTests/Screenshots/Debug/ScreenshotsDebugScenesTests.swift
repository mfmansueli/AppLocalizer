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
}
#endif
