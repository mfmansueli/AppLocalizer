//
//  FakePushingScreenshotsServices.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
@testable import AppLocalizer

/// `FakeScreenshotsServices` that can push, through
/// `FakeScreenshotPushServices`.
@MainActor
final class FakePushingScreenshotsServices: ScreenshotsServices, ScreenshotPushProviding {
    let base: FakeScreenshotsServices
    let pushServices: FakeScreenshotPushServices

    init(base: FakeScreenshotsServices, push: FakeScreenshotPushServices) {
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
        try await base.liveScreenshots(for: app, localizations: localizations)
    }

    func captureImage(_ capture: ScreenshotCapture, for app: StoreApp, pixelWidth: Int) async -> CGImage? {
        await base.captureImage(capture, for: app, pixelWidth: pixelWidth)
    }

    func liveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        await base.liveImage(screenshot, pixelWidth: pixelWidth)
    }

    func otherDisplayTypeNotes(for app: StoreApp) -> [ScreenshotDisplayType: String] {
        base.otherDisplayTypeNotes(for: app)
    }

    func uploadFont(from url: URL) async throws -> String {
        try await base.uploadFont(from: url)
    }
}
