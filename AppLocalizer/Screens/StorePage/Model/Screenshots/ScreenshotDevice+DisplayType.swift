//
//  ScreenshotDevice+DisplayType.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotDevice {
    /// The column an App Store Connect `screenshotDisplayType` counts
    /// under: every iPhone size under iPhone, every iPad size under iPad,
    /// `APP_DESKTOP` under Mac. Watch, TV and Vision Pro aren't shown.
    init?(displayType: String) {
        if displayType.hasPrefix("APP_IPHONE") {
            self = .iPhone
        } else if displayType.hasPrefix("APP_IPAD") {
            self = .iPad
        } else if displayType == "APP_DESKTOP" {
            self = .mac
        } else {
            return nil
        }
    }

    /// Screenshots per column for one locale's sets: the fullest set of
    /// each device, since the App Store scales the largest size down.
    static func counts(in sets: [(displayType: String, count: Int)]) -> [ScreenshotDevice: Int] {
        var counts: [ScreenshotDevice: Int] = [:]
        for set in sets {
            guard let device = ScreenshotDevice(displayType: set.displayType) else { continue }
            counts[device] = max(counts[device] ?? 0, set.count)
        }
        return counts
    }
}
