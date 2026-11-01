//
//  DebugScreenshotsServices.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation

/// `ScreenshotsServices` for DEBUG scenes: Lumen Journal's sample
/// screenshots (`ScreenshotsSampleData`) in one of the design's states,
/// captures drawn from a mock of Lumen's interface, the "Northpier" brand
/// font standing in as Futura, and renders kept in memory. Other apps have
/// nothing yet. Never contacts App Store Connect.
@MainActor
final class DebugScreenshotsServices: ScreenshotsServices {
    let scenario: ScreenshotsDebugScenario
    let renderHoldCount: Int?
    let fonts = ScreenshotFontCatalog(aliases: ["Northpier Display": "Futura", "Northpier": "Futura"], uploaded: ["Northpier Display"])
    /// Answers with the sample captions, a little slowly.
    var translator: any ListingTranslator = DebugCaptionTranslator()
    let renderCacheDirectory: URL? = nil
    var opening: ScreenshotsDebugOpening?
    /// The scenes made before Preview open on Sets; Studio scenes on
    /// Preview.
    var initialTab: ScreenshotsTab = .sets
    /// Studio scenes' Autopilot, holding its stages.
    var autopilot: AutopilotCenter?
    var appSupport: AppSupportCenter?
    /// Scenes report to the shared center, which the toolbar reads; tests
    /// keep theirs apart.
    let documentCenter: ScreenshotsDocumentCenter?
    private let store = InMemoryScreenshotsDocumentStore()
    private let captures = MockLumenCaptureRenderer()

    init(
        scenario: ScreenshotsDebugScenario = .standard,
        renderHoldCount: Int? = nil,
        opening: ScreenshotsDebugOpening? = nil,
        documentCenter: ScreenshotsDocumentCenter? = nil
    ) {
        self.scenario = scenario
        self.renderHoldCount = renderHoldCount
        self.opening = opening
        self.documentCenter = documentCenter
    }

    func document(for app: StoreApp, primaryLocale: StoreLocale) async throws -> ScreenshotsDocument {
        if let saved = try store.load(appID: app.id) { return saved }
        guard app.id == DebugFixtures.AppID.lumen else { return .empty(primary: primaryLocale.code) }
        return ScreenshotsDebugDocuments.document(for: scenario)
    }

    func save(_ document: ScreenshotsDocument, for app: StoreApp) async throws {
        try store.save(document, appID: app.id)
    }

    func liveScreenshots(for app: StoreApp, localizations _: [StoreLocale: String]) async throws -> LiveScreenshots {
        guard app.id == DebugFixtures.AppID.lumen, scenario != .noCaptures else { return LiveScreenshots() }
        return scenario == .everyDevice ? DebugEveryDevice.live : ScreenshotsDebugDocuments.live
    }

    func captureImage(_ capture: ScreenshotCapture, for _: StoreApp, pixelWidth: Int) async -> CGImage? {
        captures.image(for: capture, pixelWidth: pixelWidth)
    }

    /// Only English (U.K.)'s hand-uploaded set is shown from App Store
    /// Connect; it's drawn with the old look it was made with.
    func liveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        if let capture = DebugEveryDevice.liveWatchCapture(for: screenshot.id) {
            return captures.image(for: capture, pixelWidth: pixelWidth)
        }
        guard let source = ScreenshotsDebugDocuments.legacySource(for: screenshot.id),
              let locale = StoreLocaleCatalog.locale(code: source.locale) else { return nil }
        let caption = ScreenshotCaption(headline: ScreenshotsSampleData.legacyCaptions[source.slot])
        let layout = ScreenshotLayoutEngine(catalog: fonts).layout(
            ScreenshotsSampleData.legacyTemplate, slot: source.slot, locale: locale, displayType: source.displayType, caption: caption
        )
        let capture = ScreenshotsSampleData.capture(locale: "en-US", display: source.displayType, slot: source.slot)
        let image = captures.image(for: capture, pixelWidth: pixelWidth)
        return ScreenshotImageRenderer.image(layout: layout, capture: image, pixelWidth: pixelWidth)
    }

    /// Registers the font in a temporary folder, never in Application
    /// Support.
    func uploadFont(from url: URL) async throws -> String {
        try ScreenshotFontLibrary(directory: URL.temporaryDirectory.appending(path: "AppLocalizer-DebugFonts")).upload(url)
    }

    /// Lumen is rated 4.9 everywhere, so the templates' laurels pass.
    func storeRatings(for _: StoreApp, countries: Set<String>) async -> StoreRatings {
        var ratings = StoreRatings.unchecked
        for country in countries { ratings.record(.rated(4.9), inCountry: country) }
        return ratings
    }

    func otherDisplayTypeNotes(for _: StoreApp) -> [ScreenshotDisplayType: String] {
        [
            .mac: String(localized: "Lumen runs on Mac as an iPad app, so the Mac App Store shows its iPad screenshots."),
            .watch: String(localized: "Lumen has no watchOS app."),
            .appleTV: String(localized: "Lumen has no tvOS app."),
            .visionPro: String(localized: "Shown with the iPad screenshots in compatible mode."),
        ]
    }
}
#endif
