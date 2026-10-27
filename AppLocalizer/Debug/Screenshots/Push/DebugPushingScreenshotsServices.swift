//
//  DebugPushingScreenshotsServices.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation

/// The Screenshots view's DEBUG services with a simulated push behind them:
/// Lumen's live sets come from what the push has done so far, and its
/// live screenshots are drawn (or read back from what was uploaded).
@MainActor
final class DebugPushingScreenshotsServices: ScreenshotsServices, ScreenshotPushProviding {
    let base: DebugScreenshotsServices
    let pushServices: DebugScreenshotPushServices

    init(base: DebugScreenshotsServices = DebugScreenshotsServices(), push: DebugScreenshotPushServices) {
        self.base = base
        pushServices = push
    }

    var pushing: any ScreenshotPushServices { pushServices }
    var fonts: ScreenshotFontCatalog { base.fonts }
    var translator: any ListingTranslator { base.translator }
    var renderCacheDirectory: URL? { base.renderCacheDirectory }
    var renderHoldCount: Int? { base.renderHoldCount }

    func document(for app: StoreApp, primaryLocale: StoreLocale) async throws -> ScreenshotsDocument {
        try await base.document(for: app, primaryLocale: primaryLocale)
    }

    func save(_ document: ScreenshotsDocument, for app: StoreApp) async throws {
        try await base.save(document, for: app)
    }

    func liveScreenshots(for app: StoreApp, localizations: [StoreLocale: String]) async throws -> LiveScreenshots {
        guard app.id == DebugFixtures.AppID.lumen else { return try await base.liveScreenshots(for: app, localizations: localizations) }
        return pushServices.transport.live(previews: ScreenshotsDebugDocuments.live.previewSets)
    }

    func captureImage(_ capture: ScreenshotCapture, for app: StoreApp, pixelWidth: Int) async -> CGImage? {
        await base.captureImage(capture, for: app, pixelWidth: pixelWidth)
    }

    func liveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        if let data = pushServices.transport.data(forScreenshot: screenshot.id) { return ScreenshotPNG.image(data) }
        return pushServices.sampleImage(screenshot.id, pixelWidth: pixelWidth)
    }

    func otherDisplayTypeNotes(for app: StoreApp) -> [ScreenshotDisplayType: String] {
        base.otherDisplayTypeNotes(for: app)
    }

    func uploadFont(from url: URL) async throws -> String {
        try await base.uploadFont(from: url)
    }
}
#endif
