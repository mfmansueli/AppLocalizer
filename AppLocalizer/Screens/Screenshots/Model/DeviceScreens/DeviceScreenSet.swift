//
//  DeviceScreenSet.swift
//  AppLocalizer
//

import Foundation

/// A device's own screens in the set, in order: Apple Watch's real
/// captures, or Apple Vision Pro's windows.
struct DeviceScreenSet: Codable, Hashable, Sendable {
    var displayType: ScreenshotDisplayType
    var screens: [DeviceScreen]
}
