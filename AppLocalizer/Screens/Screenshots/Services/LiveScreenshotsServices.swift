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
    var ratingLookup = StoreRatingLookup()
    var renderCacheDirectory: URL? = URL.cachesDirectory.appending(path: "AppLocalizer/Renders", directoryHint: .isDirectory)
    var renderHoldCount: Int? { nil }
    var documentCenter: ScreenshotsDocumentCenter? { .shared }
    var autopilot: AutopilotCenter? { .shared }
    var appSupport: AppSupportCenter? { .shared }

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

    /// Reads a capture's text with Vision, at up to 2000 pixels wide.
    func readText(of capture: ScreenshotCapture, for app: StoreApp, locale: StoreLocale, primary: StoreLocale) async -> CaptureTextReading? {
        guard let image = await captureImage(capture, for: app, pixelWidth: 2000) else { return nil }
        return await CaptureTextReader.reading(of: image, language: locale.languageIdentifier, primary: primary.languageIdentifier)
    }

    /// Writes an Autopilot capture into the app's `Captures` folder, named
    /// by its checksum like an imported one.
    func storeCapture(_ data: Data, for app: StoreApp) async throws -> CaptureFile {
        let file = try Self.captureFile(for: data)
        let folder = capturesRoot.appending(path: "\(app.id)/Captures", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: folder.appending(path: "\(file.id).png"), options: .atomic)
        return file
    }

    /// Copies each file (or downloads each live screenshot at full size)
    /// into the app's `Captures` folder, named by its checksum.
    func importCaptures(_ items: [CaptureImportItem], for app: StoreApp) async throws -> [ScreenshotCapture] {
        let folder = capturesRoot.appending(path: "\(app.id)/Captures", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let date = Date.now
        var captures: [ScreenshotCapture] = []
        for item in items {
            let data = try await Self.data(of: item.candidate)
            let id = ScreenshotPNG.checksum(data)
            try data.write(to: folder.appending(path: "\(id).png"), options: .atomic)
            let size = ScreenshotPNG.image(data).map { PixelSize(width: $0.width, height: $0.height) }
            captures.append(item.capture(id: id, pixelSize: size, date: date))
        }
        return captures
    }

    private static func data(of candidate: CaptureCandidate) async throws -> Data {
        switch candidate.origin {
        case let .file(url):
            guard let data = await Task.detached(operation: { try? Data(contentsOf: url) }).value else {
                throw CaptureImportError.unreadable(candidate.path)
            }
            return data
        case let .live(shot):
            guard let url = shot.imageURL(width: shot.pixelSize?.width ?? 0),
                  let (data, _) = try? await URLSession.shared.data(from: url) else { throw CaptureImportError.unreadable(candidate.path) }
            return data
        }
    }

    func liveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        guard let url = screenshot.imageURL(width: pixelWidth),
              let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return ScreenshotPNG.image(data)
    }

    func uploadFont(from url: URL) async throws -> String {
        try fontLibrary.upload(url)
    }

    /// What the App Store shows on the app's page in each country.
    func storeRatings(for app: StoreApp, countries: Set<String>) async -> StoreRatings {
        await ratingLookup.ratings(appID: app.id, countries: countries)
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
