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
        try await ScreenshotsContext(content: StorePageContentLoader(client: client).content(for: app, versionID: nil))
    }

    func liveImageData(_ screenshot: LiveScreenshot) async throws -> Data {
        let width = screenshot.pixelSize?.width ?? ScreenshotDisplayType.iPhone.portraitPixelSize.width
        guard let url = screenshot.imageURL(width: width) else { throw AppStoreConnectError.unexpectedPayload }
        return try await client.download(url)
    }
}
