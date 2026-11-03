//
//  AppPreviewClip.swift
//  AppLocalizer
//

import Foundation

/// A moment the person chose at Pick for the App Preview: a screen's
/// stretch of the recording, or of a new take of it.
struct AppPreviewClip: Hashable, Sendable {
    var screenID: String
    /// Seconds from the start of its file.
    var start: Double
    var end: Double
    /// A new take of the moment; nil plays it from the device's recording.
    var source: URL?

    var seconds: Double { max(0, end - start) }
}
