//
//  AutopilotDeviceScreens.swift
//  AppLocalizer
//

import Foundation

/// The screens a device with screens of its own captures: Apple Watch's
/// (from the watch app), or Apple Vision Pro's windows, each the same
/// moment as an iPhone screen.
struct AutopilotDeviceScreens: Codable, Hashable, Sendable {
    var displayType: ScreenshotDisplayType
    var screens: [AutopilotScreen]
}
