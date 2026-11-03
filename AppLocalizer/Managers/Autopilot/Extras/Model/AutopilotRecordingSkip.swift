//
//  AutopilotRecordingSkip.swift
//  AppLocalizer
//

import Foundation

/// A recording the assistant couldn't make, and why. The run goes on: the
/// App Preview there uses the primary language's recording, or isn't made.
struct AutopilotRecordingSkip: Codable, Hashable, Sendable {
    var target: AutopilotRecordingTarget
    var reason: String
    var reportedAt: Date
}
