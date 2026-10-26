//
//  ScreenshotsServices.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// What the Screenshots view needs from outside itself.
/// `LiveScreenshotsServices` reads App Store Connect and keeps the app's
/// screenshot document on this Mac; DEBUG scenes and tests use canned data.
@MainActor
protocol ScreenshotsServices {
    /// The app's template history, captions, capture index, scope, push
    /// records and waiting proposals; an empty document the first time.
    func document(for app: StoreApp, primaryLocale: StoreLocale) async throws -> ScreenshotsDocument

    func save(_ document: ScreenshotsDocument, for app: StoreApp) async throws

    /// The screenshot and App Preview sets live on the version, per locale.
    /// `localizations` maps each locale to its `appStoreVersionLocalizations`
    /// ID.
    func liveScreenshots(for app: StoreApp, localizations: [StoreLocale: String]) async throws -> LiveScreenshots

    /// A capture's image, about `pixelWidth` pixels wide (never wider than
    /// the file).
    func captureImage(_ capture: ScreenshotCapture, for app: StoreApp, pixelWidth: Int) async -> CGImage?

    /// A live screenshot's image, about `pixelWidth` pixels wide.
    func liveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage?

    /// Why each display type templates don't render is left out, for the
    /// display-type menu's "Not in this app" section.
    func otherDisplayTypeNotes(for app: StoreApp) -> [ScreenshotDisplayType: String]

    /// The fonts templates can use, with any aliases for uploaded fonts.
    var fonts: ScreenshotFontCatalog { get }

    /// Where renders are cached between launches; nil keeps them in memory.
    var renderCacheDirectory: URL? { get }

    /// DEBUG scenes stop the render queue after this many renders, to show
    /// rendering in progress. Nil renders everything.
    var renderHoldCount: Int? { get }
}
