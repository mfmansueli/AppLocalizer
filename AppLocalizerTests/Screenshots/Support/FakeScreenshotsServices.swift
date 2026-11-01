//
//  FakeScreenshotsServices.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
@testable import AppLocalizer

/// `ScreenshotsServices` with a document and live sets in memory, captures
/// drawn as flat grey images of their pixel size, and a count of saves.
/// Nothing reaches App Store Connect or the disk.
@MainActor
final class FakeScreenshotsServices: ScreenshotsServices {
    var storedDocument: ScreenshotsDocument?
    var live = LiveScreenshots()
    var error: (any Error)?
    var fonts = ScreenshotFontCatalog(aliases: ["Northpier Display": "Futura", "Northpier": "Futura"])
    var renderCacheDirectory: URL?
    var translator: any ListingTranslator = FakeListingTranslator()
    /// Where uploaded fonts go: a temporary folder per fake.
    var fontLibrary = ScreenshotFontLibrary(directory: URL.temporaryDirectory.appending(path: "AppLocalizerTests-Fonts-\(UUID().uuidString)"))
    var renderHoldCount: Int?
    private(set) var saved: [ScreenshotsDocument] = []
    /// The App Store's ratings; unchecked by default.
    var ratings = StoreRatings.unchecked
    /// The countries each rating lookup asked about.
    private(set) var ratingLookups: [Set<String>] = []

    init(document: ScreenshotsDocument? = nil, live: LiveScreenshots = LiveScreenshots()) {
        storedDocument = document
        self.live = live
    }

    func document(for _: StoreApp, primaryLocale: StoreLocale) async throws -> ScreenshotsDocument {
        if let error { throw error }
        return storedDocument ?? .empty(primary: primaryLocale.code)
    }

    func save(_ document: ScreenshotsDocument, for _: StoreApp) async throws {
        storedDocument = document
        saved.append(document)
    }

    func liveScreenshots(for _: StoreApp, localizations _: [StoreLocale: String]) async throws -> LiveScreenshots {
        if let error { throw error }
        return live
    }

    func captureImage(_ capture: ScreenshotCapture, for _: StoreApp, pixelWidth: Int) async -> CGImage? {
        let size = capture.pixelSize
        let height = max(1, pixelWidth * size.height / max(1, size.width))
        return Self.flatImage(width: pixelWidth, height: height)
    }

    func liveImage(_: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        Self.flatImage(width: pixelWidth, height: pixelWidth * 2)
    }

    func uploadFont(from url: URL) async throws -> String {
        try fontLibrary.upload(url)
    }

    func storeRatings(for _: StoreApp, countries: Set<String>) async -> StoreRatings {
        ratingLookups.append(countries)
        return ratings
    }

    func otherDisplayTypeNotes(for _: StoreApp) -> [ScreenshotDisplayType: String] {
        [.mac: "No Mac app."]
    }

    static func flatImage(width: Int, height: Int) -> CGImage? {
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(gray: 0.85, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
