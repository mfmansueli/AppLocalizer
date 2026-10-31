//
//  AutopilotCaptureReport.swift
//  AppLocalizer
//

import Foundation

/// What the assistant says about a capture it sends: which screen,
/// language and device, the attempt, and how good it is.
struct AutopilotCaptureReport: Hashable, Sendable {
    var target: AutopilotCaptureTarget
    /// 1–3.
    var attempt: Int = 1
    /// 0–1.
    var score: Double = 1
    /// Why it scored so.
    var notes: String = ""
}
