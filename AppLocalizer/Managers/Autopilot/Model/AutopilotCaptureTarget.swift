//
//  AutopilotCaptureTarget.swift
//  AppLocalizer
//

import Foundation

/// One screen on one device in one language.
struct AutopilotCaptureTarget: Codable, Hashable, Sendable {
    var screenID: String
    var displayType: ScreenshotDisplayType
    var locale: String
}
