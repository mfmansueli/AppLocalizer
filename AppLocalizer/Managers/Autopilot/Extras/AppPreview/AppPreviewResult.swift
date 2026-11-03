//
//  AppPreviewResult.swift
//  AppLocalizer
//

import Foundation

/// A finished App Preview: the file, the rules it was made for, the poster
/// frame's time code for App Store Connect, what the file turned out to be,
/// and what still keeps it from being uploaded.
struct AppPreviewResult: Hashable, Sendable {
    var output: AppPreviewOutput
    var spec: AppPreviewSpec
    /// HH:MM:SS:FF, e.g. "00:00:05:00".
    var posterTimeCode: String
    /// Nil when the file couldn't be read back.
    var facts: AppPreviewFacts?
    /// One plain sentence each; empty when it's ready.
    var issues: [String]
    /// The screens' moments, in the order they play.
    var segments: [AppPreviewSegment]
    var endCardSeconds: Double

    var isReady: Bool { facts != nil && issues.isEmpty }
}
