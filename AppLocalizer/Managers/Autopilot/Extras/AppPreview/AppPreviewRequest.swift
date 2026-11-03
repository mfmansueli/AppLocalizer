//
//  AppPreviewRequest.swift
//  AppLocalizer
//

import Foundation

/// Everything one App Preview is made from: the Simulator recording with
/// the marks of when each screen shows up, the plan's screens with their
/// captions in one language, the screenshots' template, how it's cut, its
/// music, and where the file goes.
struct AppPreviewRequest: Sendable {
    var recording: URL
    /// The recording's size in pixels; a landscape recording makes a
    /// landscape App Preview.
    var recordingSize: PixelSize
    var recordingSeconds: Double
    var marks: [AutopilotRecordingMark]
    /// In the plan's order.
    var screens: [AppPreviewScreen]
    var template: ScreenshotTemplate
    var locale: StoreLocale
    /// For the end card.
    var appName: String
    var displayType: ScreenshotDisplayType
    var fonts: ScreenshotFontCatalog = .standard
    /// The `.mov` to write; an existing file is replaced.
    var output: URL
    /// The order, length, caption size and end card.
    var cut = AppPreviewCut()
    /// Nil writes a silent sound track.
    var music: AppPreviewMusicSource?
    /// The moments chosen at Pick; nil cuts every screen from the marks.
    var clips: [AppPreviewClip]?
}
