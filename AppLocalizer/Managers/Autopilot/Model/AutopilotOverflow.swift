//
//  AutopilotOverflow.swift
//  AppLocalizer
//

import Foundation

/// A caption that doesn't fit with the chosen direction, waiting for the
/// assistant to shorten it.
struct AutopilotOverflow: Codable, Hashable, Sendable {
    var locale: String
    var slot: Int
    var displayType: ScreenshotDisplayType
    var headline: String
    var subhead: String?
    var maxLines: Int
    /// The share of the box the text needs at the smallest size, e.g. 1.3.
    var fill: Double
}
