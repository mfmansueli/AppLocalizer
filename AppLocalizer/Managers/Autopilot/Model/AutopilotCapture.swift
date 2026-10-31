//
//  AutopilotCapture.swift
//  AppLocalizer
//

import Foundation

/// A screenshot the assistant took of one screen, ranked by its score.
/// The image is kept with the app's captures, named by `captureID`.
struct AutopilotCapture: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var target: AutopilotCaptureTarget
    /// 1–3: the assistant captures a screen up to three times.
    var attempt: Int
    /// 0–1: content filled in, no keyboard, alert or spinner, nothing
    /// private, matches the caption.
    var score: Double
    /// Why it scored so, e.g. "Keyboard covers the prompt".
    var notes: String
    /// The PNG's checksum: the file's name with the app's captures.
    var captureID: String
    var pixelSize: PixelSize
    var receivedAt: Date

    /// The capture as the screenshot document keeps it, to load its image.
    func screenshotCapture(slot: Int) -> ScreenshotCapture {
        ScreenshotCapture(
            id: captureID, locale: target.locale, displayType: target.displayType, slot: slot, source: .autopilot,
            fileName: "\(captureID).png", pixelSize: pixelSize, importedAt: receivedAt
        )
    }
}
