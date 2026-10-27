//
//  ScreenshotPushServices.swift
//  AppLocalizer
//

import Foundation

/// What a screenshot push needs besides the Screenshots view's services:
/// where requests go, where replaced screenshots and discards are kept, the
/// version screenshots go with, and the files of live screenshots.
/// `LiveScreenshotPushServices` is the real one; DEBUG scenes and tests
/// simulate App Store Connect.
@MainActor
protocol ScreenshotPushServices {
    var uploads: any ScreenshotUploadTransport { get }
    var backups: any ScreenshotBackupStore { get }
    var state: any ScreenshotPushStateStore { get }

    /// The version screenshots go with (the newest editable one, else the
    /// live one) and its localizations' IDs.
    func context(for app: StoreApp) async throws -> ScreenshotsContext

    /// A live screenshot's file at full size, to keep before it's deleted.
    func liveImageData(_ screenshot: LiveScreenshot) async throws -> Data
}
