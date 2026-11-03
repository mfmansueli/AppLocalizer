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

    /// Copies a font file where AppLocalizer keeps uploaded fonts and
    /// registers it for this process. Returns its family name.
    func uploadFont(from url: URL) async throws -> String

    /// Translates captions: the Store Page's translator (Apple Translation
    /// on this Mac).
    var translator: any ListingTranslator { get }

    /// Where renders are cached between launches; nil keeps them in memory.
    var renderCacheDirectory: URL? { get }

    /// DEBUG scenes stop the render queue after this many renders, to show
    /// rendering in progress. Nil renders everything.
    var renderHoldCount: Int? { get }

    /// Keeps the Screenshots view, the Proposals sheet and the assistant
    /// tools showing one app's document in step; nil keeps nobody else
    /// informed. Defaults to nil.
    var documentCenter: ScreenshotsDocumentCenter? { get }

    /// Copies an import's files where captures are kept and returns their
    /// records. By default it keeps no files: the records alone.
    func importCaptures(_ items: [CaptureImportItem], for app: StoreApp) async throws -> [ScreenshotCapture]

    /// Exports Xcode result bundles' attachments for an import.
    var attachmentReader: any XcresultAttachmentReader { get }

    /// Screenshot Autopilot's runs, shared with the assistant tools; nil
    /// when Autopilot isn't available. Defaults to nil.
    var autopilot: AutopilotCenter? { get }
    /// What each app's Xcode project supports: the devices Autopilot plans
    /// and the languages beyond the App Store page.
    var appSupport: AppSupportCenter? { get }

    /// The view the Screenshots section opens on: Preview, except in DEBUG
    /// scenes made for the other tabs. Defaults to Preview.
    var initialTab: ScreenshotsTab { get }

    /// The app's average App Store rating in each country, for checking
    /// the ratings templates show. By default nothing is looked up.
    func storeRatings(for app: StoreApp, countries: Set<String>) async -> StoreRatings

    /// Keeps a PNG the assistant captured with the app's captures, named by
    /// its checksum. By default it keeps nothing and only reads the size.
    func storeCapture(_ data: Data, for app: StoreApp) async throws -> CaptureFile

    /// Keeps a Simulator recording the assistant sent for the App Preview,
    /// named by its checksum. By default it's kept in a temporary folder.
    func storeRecording(_ data: Data, for app: StoreApp) async throws -> RecordingFile

    /// Where a kept recording is.
    func recordingURL(_ fileID: String, for app: StoreApp) -> URL

    /// The folder the app's header and search artwork and App Previews are
    /// made in. By default a temporary one.
    func extrasFolder(for app: StoreApp) -> URL

    /// The text in a capture, read in `locale`'s language and the ones an
    /// app falls back to (`primary`, English). By default nothing is read.
    func readText(of capture: ScreenshotCapture, for app: StoreApp, locale: StoreLocale, primary: StoreLocale) async -> CaptureTextReading?
}
