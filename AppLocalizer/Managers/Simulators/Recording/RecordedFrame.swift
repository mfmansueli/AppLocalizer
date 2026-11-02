//
//  RecordedFrame.swift
//  AppLocalizer
//

import Foundation

/// One frame of a display's recording (`DisplayRecording`): its file in the
/// recording's folder, when the capture that made it started and ended, and
/// until when the display still looked the same. Times are seconds since
/// 1970, like XCTest's in a result bundle.
struct RecordedFrame: Hashable, Sendable {
    var file: String
    var start: Double
    var end: Double
    /// When the last capture that matched it ended.
    var lastSeen: Double
}
