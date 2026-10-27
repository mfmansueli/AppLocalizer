//
//  ScreenshotDeliveryMessage.swift
//  AppLocalizer
//

import Foundation

/// An error or warning in an asset's delivery state.
struct ScreenshotDeliveryMessage: Codable, Hashable, Sendable {
    var code: String?
    var description: String?
}
