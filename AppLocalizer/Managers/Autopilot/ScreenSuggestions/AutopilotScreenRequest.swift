//
//  AutopilotScreenRequest.swift
//  AppLocalizer
//

import Foundation

/// Suggest Screens, asked and not answered yet: what the person asked for
/// ("one that shows the streak"), if anything, and for which device.
struct AutopilotScreenRequest: Codable, Hashable, Sendable {
    var ask: String?
    var askedAt: Date
    /// Apple Watch, for its own screens; nil for the set's, on iPhone and
    /// iPad.
    var displayType: ScreenshotDisplayType?

    /// The device whose screens are asked for: iPhone stands for the set.
    var device: ScreenshotDisplayType { displayType ?? .iPhone }
}
