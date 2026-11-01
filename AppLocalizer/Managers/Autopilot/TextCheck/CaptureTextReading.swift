//
//  CaptureTextReading.swift
//  AppLocalizer
//

import Foundation

/// What Vision read in a capture, and whether it can read the capture's
/// language at all: Hebrew and Hindi, say, it can't, and then the
/// language isn't judged.
struct CaptureTextReading: Hashable, Sendable {
    var lines: [RecognizedTextLine]
    var readsLanguage: Bool
}
