//
//  FakeScreenshotPushServices.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// `ScreenshotPushServices` with a fake App Store Connect, backups and
/// state in memory, and a fixed version context.
@MainActor
final class FakeScreenshotPushServices: ScreenshotPushServices {
    let transport: FakeScreenshotUploadTransport
    let backupStore = InMemoryScreenshotBackupStore()
    let stateStore = InMemoryScreenshotPushStateStore()
    var screenshotsContext: ScreenshotsContext
    private(set) var contextCount = 0

    init(transport: FakeScreenshotUploadTransport = FakeScreenshotUploadTransport(), context: ScreenshotsContext) {
        self.transport = transport
        screenshotsContext = context
    }

    var uploads: any ScreenshotUploadTransport { transport }
    var backups: any ScreenshotBackupStore { backupStore }
    var state: any ScreenshotPushStateStore { stateStore }

    func context(for _: StoreApp) async throws -> ScreenshotsContext {
        contextCount += 1
        return screenshotsContext
    }

    func liveImageData(_ screenshot: LiveScreenshot) async throws -> Data {
        Data("file of \(screenshot.id)".utf8)
    }
}
