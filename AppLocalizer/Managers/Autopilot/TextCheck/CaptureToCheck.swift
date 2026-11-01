//
//  CaptureToCheck.swift
//  AppLocalizer
//

import Foundation

/// A capture the set uses whose text gives something away, for the Pick
/// step's "Captures to check".
struct CaptureToCheck: Hashable, Identifiable, Sendable {
    var target: AutopilotCaptureTarget
    var captureID: String
    var issues: [CaptureTextIssue]

    var id: String { captureID }
}
