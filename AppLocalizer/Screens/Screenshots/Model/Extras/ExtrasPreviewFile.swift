//
//  ExtrasPreviewFile.swift
//  AppLocalizer
//

import Foundation

/// One App Preview: a device in a language, the movie's checksum (the
/// file's name), its length, size and poster frame, and what Apple's
/// rules check found.
struct ExtrasPreviewFile: Codable, Hashable, Sendable, Identifiable {
    var displayType: ScreenshotDisplayType
    var locale: String
    /// The language whose recording it's cut from.
    var recordedLocale: String
    var fileID: String
    var seconds: Double
    var pixelSize: PixelSize
    var byteCount: Int
    /// The poster frame, in seconds.
    var posterSeconds: Double
    /// Each rule it breaks, in a sentence; empty when it passes.
    var problems: [String] = []
    /// What plays when, end card last; nil in files from before.
    var scenes: [ExtrasPreviewScene]?

    var id: String { "\(displayType.mcpValue)-\(locale)" }
    var fileName: String { "AppPreview-\(displayType.shortTitle)-\(locale).mov" }

    /// "0:24".
    var lengthTitle: String { Self.lengthTitle(seconds) }

    /// The poster frame as App Store Connect takes it: "00:00:05:00".
    var posterTimeCode: String {
        let whole = Int(posterSeconds)
        let frames = Int(((posterSeconds - Double(whole)) * 30).rounded())
        return String(format: "00:00:%02d:%02d", whole, min(frames, 29))
    }

    static func lengthTitle(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
