//
//  CaptureTextFacts.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer read in a capture: the language most of its text is
/// in, the lines cut off with an ellipsis, and a line that looks like a
/// system prompt. Kept with the capture; `AutopilotRun.textIssues(of:)`
/// says which of them are a problem.
struct CaptureTextFacts: Codable, Hashable, Sendable {
    /// "en", "de", "zh-Hans"; nil with too little text, a mix, or a
    /// language Vision can't read.
    var language: String?
    /// "Einträge durchsu…".
    var truncatedLines: [String] = []
    /// "“Lumen” Would Like to Send You Notifications".
    var promptLine: String?
}
