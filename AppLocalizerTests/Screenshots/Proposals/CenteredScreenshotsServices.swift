//
//  CenteredScreenshotsServices.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
@testable import AppLocalizer

/// `FakeScreenshotsServices` reporting to a document center of the test's
/// own, so a Screenshots view model, a Proposals sheet and the tools stay
/// in step the way they do in the app.
@MainActor
final class CenteredScreenshotsServices: ScreenshotsServices {
    let fake: FakeScreenshotsServices
    let documentCenter: ScreenshotsDocumentCenter?

    init(document: ScreenshotsDocument, center: ScreenshotsDocumentCenter = ScreenshotsDocumentCenter()) {
        fake = FakeScreenshotsServices(document: document, live: ScreenshotsDebugDocuments.live)
        documentCenter = center
    }

    var center: ScreenshotsDocumentCenter { documentCenter ?? ScreenshotsDocumentCenter() }
    var storedDocument: ScreenshotsDocument? { fake.storedDocument }
    var fonts: ScreenshotFontCatalog { fake.fonts }
    var translator: any ListingTranslator { fake.translator }
    var renderCacheDirectory: URL? { nil }
    var renderHoldCount: Int? { nil }

    func document(for app: StoreApp, primaryLocale: StoreLocale) async throws -> ScreenshotsDocument {
        try await fake.document(for: app, primaryLocale: primaryLocale)
    }

    func save(_ document: ScreenshotsDocument, for app: StoreApp) async throws {
        try await fake.save(document, for: app)
    }

    func liveScreenshots(for app: StoreApp, localizations: [StoreLocale: String]) async throws -> LiveScreenshots {
        try await fake.liveScreenshots(for: app, localizations: localizations)
    }

    func captureImage(_ capture: ScreenshotCapture, for app: StoreApp, pixelWidth: Int) async -> CGImage? {
        await fake.captureImage(capture, for: app, pixelWidth: pixelWidth)
    }

    func liveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        await fake.liveImage(screenshot, pixelWidth: pixelWidth)
    }

    func otherDisplayTypeNotes(for app: StoreApp) -> [ScreenshotDisplayType: String] {
        fake.otherDisplayTypeNotes(for: app)
    }

    func uploadFont(from url: URL) async throws -> String {
        try await fake.uploadFont(from: url)
    }
}
