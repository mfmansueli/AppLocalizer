//
//  CaptureScan.swift
//  AppLocalizer
//

import Foundation

/// What a scan of dropped or chosen files found: the kind of output it
/// looks like, where it came from, and every screenshot in it.
struct CaptureScan: Hashable, Sendable {
    var source: CaptureSource
    /// "~/Developer/Lumen/fastlane/screenshots".
    var location: String
    var candidates: [CaptureCandidate]
}
