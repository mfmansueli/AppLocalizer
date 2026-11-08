//
//  GuidedTemplatePreviewDevices.swift
//  AppLocalizer
//

import Foundation

/// The devices the Look step previews a template on: every device the app
/// ships on, in the App Store's order. The ones What to make chose are in
/// the run; the others carry a + and can be tried, then added from there.
enum GuidedTemplatePreviewDevices {
    /// iPhone, iPad, iPhone Duo, Mac, Apple Vision Pro, Apple Watch.
    static let order: [ScreenshotDisplayType] = [.iPhone, .iPad, .iPhoneDuo, .mac, .visionPro, .watch]

    /// `offered`, the devices the app ships on, in `order`; iPhone when
    /// none.
    static func devices(for offered: [ScreenshotDisplayType]) -> [ScreenshotDisplayType] {
        let devices = order.filter(offered.contains)
        return devices.isEmpty ? [.iPhone] : devices
    }

    /// `chosen` while it's still offered, else the first device in the run,
    /// else the first.
    static func device(_ chosen: ScreenshotDisplayType?, in devices: [ScreenshotDisplayType], inRun: [ScreenshotDisplayType] = []) -> ScreenshotDisplayType {
        if let chosen, devices.contains(chosen) { return chosen }
        return devices.first(where: inRun.contains) ?? devices.first ?? .iPhone
    }

    /// "iPhone", "iPad", "iPhone Duo", "Mac", "Vision Pro", "Apple Watch".
    static func title(_ device: ScreenshotDisplayType) -> String {
        switch device {
        case .visionPro: String(localized: "Vision Pro")
        default: device.shortTitle
        }
    }

    /// The segment: "Mac +" when the run doesn't make it yet.
    static func label(_ device: ScreenshotDisplayType, isInRun: Bool) -> String {
        isInRun ? title(device) : title(device) + " +"
    }

    /// "iPhone 6.9″ · 1320 × 2868", "iPhone Duo · inner display · 2007 ×
    /// 2853", "Mac · 2880 × 1800": `size` is the screenshot's, the device's
    /// usual size when nil.
    static func sizeTitle(_ device: ScreenshotDisplayType, size: PixelSize? = nil) -> String {
        let size = size ?? device.defaultPixelSize
        return switch device {
        case .iPhoneDuo: String(localized: "iPhone Duo · inner display · \(size.title)")
        default: "\(device.title) · \(size.title)"
        }
    }

    /// The segment's help: "iPad 13″ · 2752 × 2064 · in this run", "Mac ·
    /// 2880 × 1800 · not in this run yet".
    static func help(_ device: ScreenshotDisplayType, isInRun: Bool) -> String {
        let size = sizeTitle(device)
        return isInRun ? String(localized: "\(size) · in this run") : String(localized: "\(size) · not in this run yet")
    }

    /// "2 of 6 devices in this run · + means not in this run"; nil when the
    /// run has them all.
    static func runCount(_ devices: [ScreenshotDisplayType], inRun: [ScreenshotDisplayType]) -> String? {
        let count = devices.count(where: inRun.contains)
        guard count < devices.count else { return nil }
        return String(localized: "\(count) of \(devices.count) devices in this run · + means not in this run")
    }

    /// The device's identifier suffix: "iphone", "ipad", "iphone_duo",
    /// "mac", "vision", "watch".
    static func key(_ device: ScreenshotDisplayType) -> String {
        device.mcpValue
    }
}
