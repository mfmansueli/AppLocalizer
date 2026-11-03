//
//  AutopilotRecordingTarget.swift
//  AppLocalizer
//

import Foundation

/// One Simulator recording for the App Preview: a device in a language.
struct AutopilotRecordingTarget: Codable, Hashable, Sendable {
    var displayType: ScreenshotDisplayType
    var locale: String
}
