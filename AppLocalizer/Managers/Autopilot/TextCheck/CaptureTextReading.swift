//
//  CaptureTextReading.swift
//  AppLocalizer
//

import Foundation

/// What Vision read in a capture, and whether it can read the capture's
/// language at all: Hebrew and Hindi, say, it can't, and then the
/// language isn't judged. With it, how much of the capture is blank.
struct CaptureTextReading: Hashable, Sendable {
    var lines: [RecognizedTextLine]
    var readsLanguage: Bool
    /// `CaptureBlankness.largestBlankShare(of:)`; nil when not measured.
    var blankShare: Double?
}
