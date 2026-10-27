//
//  LiveScreenshotSet.swift
//  AppLocalizer
//

import Foundation

/// One `appScreenshotSet`: a locale's screenshots for one display type, in
/// App Store order.
struct LiveScreenshotSet: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var locale: String
    var displayType: ScreenshotDisplayType
    var screenshots: [LiveScreenshot]

    func screenshot(slot: Int) -> LiveScreenshot? {
        screenshots.indices.contains(slot) ? screenshots[slot] : nil
    }
}
