//
//  StudioTestServices.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
@testable import AppLocalizer

/// `FakeScreenshotsServices` with Screenshot Autopilot: an `AutopilotCenter`
/// and an `AppSupportCenter` of the test's own (never `.shared`) and the
/// tab the section opens on.
@MainActor
final class StudioTestServices: ScreenshotsServices {
    let fake: FakeScreenshotsServices
    var autopilot: AutopilotCenter?
    var appSupport: AppSupportCenter?
    var initialTab: ScreenshotsTab
    /// What's live in each localization, when it matters which; else the
    /// fake's sets for all of them.
    var liveForLocalizations: (([StoreLocale: String]) -> LiveScreenshots)?

    init(
        document: ScreenshotsDocument? = nil,
        live: LiveScreenshots = LiveScreenshots(),
        autopilot: AutopilotCenter? = nil,
        initialTab: ScreenshotsTab = .preview
    ) {
        fake = FakeScreenshotsServices(document: document, live: live)
        self.autopilot = autopilot
        self.initialTab = initialTab
    }

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
        if let liveForLocalizations { return liveForLocalizations(localizations) }
        return try await fake.liveScreenshots(for: app, localizations: localizations)
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
