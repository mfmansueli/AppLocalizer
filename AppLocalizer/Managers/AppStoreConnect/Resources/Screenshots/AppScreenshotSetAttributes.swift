//
//  AppScreenshotSetAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appScreenshotSets` resource's attributes.
struct AppScreenshotSetAttributes: Decodable, Sendable {
    /// E.g. `APP_IPHONE_67`, `APP_IPAD_PRO_3GEN_129` or `APP_DESKTOP`.
    var screenshotDisplayType: String
}
