//
//  AutopilotRecordingMark.swift
//  AppLocalizer
//

import Foundation

/// When one of the plan's screens appears in a recording, in seconds from
/// its start.
struct AutopilotRecordingMark: Codable, Hashable, Sendable {
    var screenID: String
    var seconds: Double
}
