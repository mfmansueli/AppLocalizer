//
//  AppPreviewSegment.swift
//  AppLocalizer
//

import Foundation

/// One screen's moment in the App Preview: where it starts in the
/// recording and how long it plays, in seconds.
struct AppPreviewSegment: Hashable, Sendable {
    var screenID: String
    /// Seconds from the recording's start.
    var start: Double
    var duration: Double
    /// A new take of the moment to play instead of the recording; nil is
    /// the recording.
    var source: URL?

    var end: Double { start + duration }
}
