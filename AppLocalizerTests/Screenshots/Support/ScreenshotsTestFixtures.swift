//
//  ScreenshotsTestFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// Lumen Journal's sample screenshot documents (the design's numbers),
/// turned into snapshots and view models for the tests.
@MainActor
enum ScreenshotsTestFixtures {
    static let app = StoreApp(id: "6450000001", name: "Lumen Journal", bundleID: "dev.example.lumen", sku: nil, primaryLocale: "en-US")

    static let fonts = ScreenshotFontCatalog(aliases: ["Northpier Display": "Futura", "Northpier": "Futura"])

    static let editableVersion = ScreenshotsVersion(id: "v14", versionString: "1.4", stateTitle: "Prepare for Submission", isEditable: true)

    static let liveVersion = ScreenshotsVersion(id: "v13", versionString: "1.3", stateTitle: "Ready for Distribution", isEditable: false)

    static func snapshot(_ document: ScreenshotsDocument, live: LiveScreenshots = ScreenshotsDebugDocuments.live) -> ScreenshotsSnapshot {
        ScreenshotsSnapshot(
            document: document, live: live, primaryLocale: .englishUS, locales: StoreLocaleCatalog.all,
            version: editableVersion, fonts: fonts
        )
    }

    static func matrix(_ document: ScreenshotsDocument) -> ScreenshotMatrix {
        ScreenshotMatrixBuilder().build(snapshot(document))
    }

    /// A loaded view model on `document` with the sample live sets.
    static func viewModel(
        _ document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard,
        version: ScreenshotsVersion = editableVersion
    ) async -> (ScreenshotsViewModel, FakeScreenshotsServices) {
        let services = FakeScreenshotsServices(document: document, live: ScreenshotsDebugDocuments.live)
        let context = ScreenshotsContext(primaryLocale: .englishUS, version: version)
        let model = ScreenshotsViewModel(app: app, services: services, context: context)
        await model.load()
        model.renderQueue.cancel()
        return (model, services)
    }

    /// The sample caption for a locale and slot.
    static func caption(_ locale: String, slot: Int) -> ScreenshotCaption? {
        ScreenshotsSampleData.caption(locale: locale, slot: slot, source: ScreenshotsSampleData.provenance)
    }
}
#endif
