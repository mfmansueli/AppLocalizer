//
//  GuidedReviewDeviceNote.swift
//  AppLocalizer
//

import Foundation

/// The line under Review & push's screenshots: the device's size and what
/// the App Store does with it, then how to see one larger. "iPhone 6.9″ ·
/// 1320 × 2868 · the App Store scales it for smaller iPhones · click one
/// to see it larger".
enum GuidedReviewDeviceNote {
    /// - Parameters:
    ///   - size: The screenshots' size; the device's usual one when nil.
    ///   - count: How many screenshots the device has.
    static func line(_ device: ScreenshotDisplayType, size: PixelSize?, app: String, count: Int) -> String {
        let title = GuidedTemplatePreviewDevices.sizeTitle(device, size: size)
        let size = size ?? device.defaultPixelSize
        let about: String? = switch device {
        case .iPhone: String(localized: "the App Store scales it for smaller iPhones")
        case .iPad: orientation(size)
        case .mac: String(localized: "\(app)’s Mac window on a MacBook")
        case .visionPro: screenshots(count)
        case .watch: String(localized: "the bare screen; Apple adds the frame")
        default: nil
        }
        return ([title, about].compactMap(\.self) + [String(localized: "click one to see it larger")]).joined(separator: " · ")
    }

    private static func orientation(_ size: PixelSize) -> String {
        if size.width > size.height { return String(localized: "landscape") }
        return String(localized: "portrait")
    }

    private static func screenshots(_ count: Int) -> String {
        if count == 1 { return String(localized: "1 screenshot") }
        return String(localized: "\(count) screenshots")
    }
}
