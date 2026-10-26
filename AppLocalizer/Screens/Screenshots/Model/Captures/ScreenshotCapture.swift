//
//  ScreenshotCapture.swift
//  AppLocalizer
//

import Foundation

/// A real screenshot of the app for one locale × display type × slot.
/// AppLocalizer never draws on or edits it (App Review guideline 2.3); the
/// template only places it.
struct ScreenshotCapture: Codable, Hashable, Sendable, Identifiable {
    /// Stable across launches; part of every render key that uses it.
    var id: String
    /// The locale whose interface it shows.
    var locale: String
    var displayType: ScreenshotDisplayType
    var slot: Int
    var source: CaptureSource
    /// The file name it was imported as, e.g.
    /// `de-DE/iPhone 17 Pro Max-01_Today.png`.
    var fileName: String
    var pixelSize: PixelSize
}
