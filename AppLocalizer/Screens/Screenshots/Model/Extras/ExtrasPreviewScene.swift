//
//  ExtrasPreviewScene.swift
//  AppLocalizer
//

import Foundation

/// One stretch of an App Preview: a screen's moment, or the end card,
/// with when it starts and how long it plays, in seconds.
struct ExtrasPreviewScene: Codable, Hashable, Sendable {
    /// The plan's screen; nil for the end card.
    var screenID: String?
    /// "Today", "End card".
    var title: String
    var start: Double
    var duration: Double

    var end: Double { start + duration }
    var isEndCard: Bool { screenID == nil }
}
