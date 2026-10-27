//
//  DebugScreenshotPushServices.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation

/// `ScreenshotPushServices` for DEBUG scenes: uploads go to a simulated
/// App Store Connect (`DebugScreenshotUploadTransport`), backups and state
/// stay in memory, and the Oct 12 push's kept sets are there to restore.
/// A scene can start pushing once the plans load, or open Restore Previous
/// Screenshots… when Activity appears. Never contacts App Store Connect.
@MainActor
final class DebugScreenshotPushServices: ScreenshotPushServices {
    let transport: DebugScreenshotUploadTransport
    let images: DebugScreenshotImages
    let backups: any ScreenshotBackupStore
    let state: any ScreenshotPushStateStore = InMemoryScreenshotPushStateStore()
    private var autoPush: Bool
    private var restoreOnOpen: ScreenshotRestorePresentation?
    private let storePage = DebugStorePageServices()

    init(
        script: DebugScreenshotUploadScript = DebugScreenshotUploadScript(),
        images: DebugScreenshotImages,
        autoPush: Bool = false,
        restoreOnOpen: ScreenshotRestorePresentation? = nil
    ) {
        transport = DebugScreenshotUploadTransport(live: ScreenshotsDebugDocuments.live, script: script)
        self.images = images
        backups = DebugKeptScreenshots(images: images, prefills: true)
        self.autoPush = autoPush
        self.restoreOnOpen = restoreOnOpen
    }

    var uploads: any ScreenshotUploadTransport { transport }

    /// Lumen's version 1.4, with a localization for every locale in the
    /// screenshot scope (the store page has texts for only some).
    func context(for app: StoreApp) async throws -> ScreenshotsContext {
        var context = try await ScreenshotsContext(content: storePage.content(for: app, versionID: nil))
        for code in ScreenshotsSampleData.scope {
            guard let locale = StoreLocaleCatalog.locale(code: code), context.localizations[locale] == nil else { continue }
            context.localizations[locale] = "debug-loc-\(code)"
        }
        transport.register(localizations: context.localizations)
        return context
    }

    /// The uploaded file, or the sample screenshot drawn small.
    func liveImageData(_ screenshot: LiveScreenshot) async throws -> Data {
        if let data = transport.data(forScreenshot: screenshot.id) { return data }
        guard let image = sampleImage(screenshot.id, pixelWidth: 480), let data = ScreenshotPNG.data(image) else {
            throw ScreenshotPushFailure.image
        }
        return data
    }

    /// One of the sample live screenshots: from template v4, or English
    /// (U.K.)'s hand-uploaded ones.
    func sampleImage(_ id: String, pixelWidth: Int) -> CGImage? {
        if let image = images.liveImage(id: id, pixelWidth: pixelWidth) { return image }
        guard let source = ScreenshotsDebugDocuments.legacySource(for: id) else { return nil }
        return images.legacyImage(locale: source.locale, displayType: source.displayType, slot: source.slot, pixelWidth: pixelWidth)?.0
    }

    /// True once, for a scene that starts pushing as soon as it opens.
    func consumeAutoPush() -> Bool {
        defer { autoPush = false }
        return autoPush
    }

    /// Restore Previous Screenshots…, once, for a scene that opens on it.
    func consumeRestoreOnOpen() -> ScreenshotRestorePresentation? {
        defer { restoreOnOpen = nil }
        return restoreOnOpen
    }
}
#endif
