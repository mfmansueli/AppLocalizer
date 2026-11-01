//
//  RecognizedTextLine.swift
//  AppLocalizer
//

import Foundation

/// One line of text Vision read in a capture: its words, how sure Vision
/// is of them (0–1), and where it starts, from 0 at the image's top to 1
/// at its bottom.
struct RecognizedTextLine: Hashable, Sendable {
    var text: String
    var confidence: Double
    var top: Double
}
