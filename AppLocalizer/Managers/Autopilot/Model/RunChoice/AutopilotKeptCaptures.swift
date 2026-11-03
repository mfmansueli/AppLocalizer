//
//  AutopilotKeptCaptures.swift
//  AppLocalizer
//

import Foundation

/// The last run's captures a new plan can reuse ("Reuse Oct 28
/// captures"): which version, when, on which devices and in how many
/// languages.
struct AutopilotKeptCaptures: Codable, Hashable, Sendable {
    var versionString: String
    var capturedAt: Date
    var displayTypes: [ScreenshotDisplayType]
    var localeCount: Int
    /// The person's picks went with them.
    var hasPicks: Bool
}
