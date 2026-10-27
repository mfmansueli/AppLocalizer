//
//  LiveScreenshotsServices.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import ImageIO

/// The real `ScreenshotsServices`: live sets from App Store Connect (one
/// request per locale for screenshots and one for App Previews, one at a
/// time), the document on this Mac, captures from its folder, renders
/// cached in Caches.
@MainActor
struct LiveScreenshotsServices: ScreenshotsServices {
    let client: AppStoreConnectClient
    var store: any ScreenshotsDocumentStore = FileScreenshotsDocumentStore()
    var capturesRoot: URL = FileScreenshotsDocumentStore.defaultRoot
    var fontLibrary = ScreenshotFontLibrary()
    /// The installed fonts and the ones uploaded before, registered now.
    var fonts = ScreenshotFontCatalog(uploaded: ScreenshotFontLibrary().registerAll())
    var translator: any ListingTranslator = AppleListingTranslator()
    var renderCacheDirectory: URL? = URL.cachesDirectory.appending(path: "AppLocalizer/Renders", directoryHint: .isDirectory)
    var renderHoldCount: Int? { nil }

    func document(for app: StoreApp, primaryLocale: StoreLocale) async throws -> ScreenshotsDocument {
        try store.load(appID: app.id) ?? .empty(primary: primaryLocale.code)
    }

    func save(_ document: ScreenshotsDocument, for app: StoreApp) async throws {
        try store.save(document, appID: app.id)
    }

    func liveScreenshots(for _: StoreApp, localizations: [StoreLocale: String]) async throws -> LiveScreenshots {
        var live = LiveScreenshots()
        for (locale, id) in localizations.sorted(by: { $0.key.code < $1.key.code }) {
            live.screenshotSets += try await client.liveScreenshotSets(localizationID: id, locale: locale.code)
            live.previewSets += try await client.livePreviewSets(localizationID: id, locale: locale.code)
        }
        return live
    }

    /// Imported captures are PNGs named by capture ID in the app's
    /// `Captures` folder.
    func captureImage(_ capture: ScreenshotCapture, for app: StoreApp, pixelWidth: Int) async -> CGImage? {
        let url = capturesRoot.appending(path: "\(app.id)/Captures/\(capture.id).png")
        return await Task.detached { Self.thumbnail(at: url, pixelWidth: pixelWidth) }.value
    }

    func liveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        guard let url = screenshot.imageURL(width: pixelWidth),
              let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return ScreenshotPNG.image(data)
    }

    func uploadFont(from url: URL) async throws -> String {
        try fontLibrary.upload(url)
    }

    func otherDisplayTypeNotes(for _: StoreApp) -> [ScreenshotDisplayType: String] {
        let note = String(localized: "Templates render iPhone and iPad screenshots; these stay as they are in App Store Connect.")
        return [.mac: note, .watch: note, .appleTV: note, .visionPro: note]
    }

    private nonisolated static func thumbnail(at url: URL, pixelWidth: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelWidth * 3,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
