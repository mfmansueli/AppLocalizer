//
//  AutopilotRecording.swift
//  AppLocalizer
//

import Foundation

/// A Simulator recording of the plan's screens that the assistant sent for
/// the App Preview (`report_recording`), with when each screen appears.
struct AutopilotRecording: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var target: AutopilotRecordingTarget
    /// The file's checksum: its name in the app's Recordings folder.
    var fileID: String
    var pixelSize: PixelSize
    var seconds: Double
    var marks: [AutopilotRecordingMark]
    var receivedAt: Date
    /// The moments Claude Code marked for the App Preview, with why; nil
    /// when it sent only when each screen shows up. Use `moments(screenIDs:)`.
    var markedMoments: [AutopilotRecordingMoment]?
    /// A take of one moment again (its screen's ID) that stands in for that
    /// moment of the device's recording; nil for a whole recording.
    var retakeOf: String?
}
