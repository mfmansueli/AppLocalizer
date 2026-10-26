//
//  LiveAppPreviewSet.swift
//  AppLocalizer
//

import Foundation

/// A locale's App Previews for one display type. Read-only here: the Sets
/// matrix shows them in their own column with a lock.
struct LiveAppPreviewSet: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var locale: String
    var displayType: ScreenshotDisplayType
    var previewCount: Int
    /// The first preview's poster-frame time code, e.g. "00:00:05:00".
    var posterFrameTimeCode: String?
    /// The length in seconds when known. App Store Connect doesn't report
    /// it, so live previews leave it nil.
    var durationSeconds: Int?

    /// "0:24", or nil when the length isn't known.
    var durationTitle: String? {
        durationSeconds.map { String(format: "%d:%02d", $0 / 60, $0 % 60) }
    }
}
