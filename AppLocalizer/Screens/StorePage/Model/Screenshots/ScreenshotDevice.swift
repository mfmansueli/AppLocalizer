//
//  ScreenshotDevice.swift
//  AppLocalizer
//

import Foundation

/// The screenshot sizes the Screenshots view shows, one column each.
enum ScreenshotDevice: String, CaseIterable, Identifiable, Hashable, Sendable {
    case iPhone
    case iPad
    case mac

    var id: String { rawValue }

    var title: String {
        switch self {
        case .iPhone: String(localized: "iPhone 6.9″")
        case .iPad: String(localized: "iPad 13″")
        case .mac: String(localized: "Mac")
        }
    }
}
