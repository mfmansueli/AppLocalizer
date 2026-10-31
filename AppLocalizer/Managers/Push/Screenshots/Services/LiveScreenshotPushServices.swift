//
//  LiveScreenshotPushServices.swift
//  AppLocalizer
//

import Foundation

/// The real `ScreenshotPushServices`: requests through the API client,
/// replaced screenshots kept in Application Support, the version from the
/// Store Page's loader.
@MainActor
struct LiveScreenshotPushServices: ScreenshotPushServices {
    let client: AppStoreConnectClient
    var backups: any ScreenshotBackupStore = FileScreenshotBackupStore()
    var state: any ScreenshotPushStateStore = FileScreenshotPushStateStore()

    var uploads: any ScreenshotUploadTransport { client }

    func context(for app: StoreApp) async throws -> ScreenshotsContext {
        let loader = StorePageContentLoader(client: client)
        let content = try await loader.content(for: app, versionID: nil)
        var context = ScreenshotsContext(content: content)
        await context.readVisionLocalizations(in: content) { id in try await loader.content(for: app, versionID: id) }
        return context
    }

    func liveImageData(_ screenshot: LiveScreenshot) async throws -> Data {
        let width = screenshot.pixelSize?.width ?? ScreenshotDisplayType.iPhone.portraitPixelSize.width
        guard let url = screenshot.imageURL(width: width) else { throw AppStoreConnectError.unexpectedPayload }
        return try await client.download(url)
    }
}
