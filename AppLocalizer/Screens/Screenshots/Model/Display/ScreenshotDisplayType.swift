//
//  ScreenshotDisplayType.swift
//  AppLocalizer
//

import Foundation

/// A set of App Store screenshots for one kind of device. iPhone 6.9″ and
/// iPad 13″ are the sizes Apple requires and AppLocalizer renders; the App
/// Store scales them down for smaller devices. Mac, Apple Watch, Apple TV
/// and Apple Vision Pro are listed so the model is visibly open to them,
/// but templates don't render them yet.
enum ScreenshotDisplayType: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case iPhone = "APP_IPHONE_67"
    case iPad = "APP_IPAD_PRO_3GEN_129"
    case mac = "APP_DESKTOP"
    case watch = "APP_WATCH_ULTRA"
    case appleTV = "APP_APPLE_TV"
    case visionPro = "APP_APPLE_VISION_PRO"

    var id: String { rawValue }

    /// The display types templates render, in menu order.
    static let rendered: [ScreenshotDisplayType] = [.iPhone, .iPad]

    var isRendered: Bool { Self.rendered.contains(self) }

    /// App Store Connect's `screenshotDisplayType`.
    var apiValue: String { rawValue }

    /// App Store Connect's `previewType` for App Previews of the same size.
    var previewType: String? {
        switch self {
        case .iPhone: "IPHONE_67"
        case .iPad: "IPAD_PRO_3GEN_129"
        case .mac: "DESKTOP"
        case .appleTV: "APPLE_TV"
        case .visionPro: "APPLE_VISION_PRO"
        case .watch: nil
        }
    }

    /// "iPhone 6.9″".
    var title: String {
        switch self {
        case .iPhone: String(localized: "iPhone 6.9″")
        case .iPad: String(localized: "iPad 13″")
        case .mac: String(localized: "Mac")
        case .watch: String(localized: "Apple Watch")
        case .appleTV: String(localized: "Apple TV")
        case .visionPro: String(localized: "Apple Vision Pro")
        }
    }

    /// "iPhone", for compact labels.
    var shortTitle: String {
        switch self {
        case .iPhone: String(localized: "iPhone")
        case .iPad: String(localized: "iPad")
        default: title
        }
    }

    /// The simulator to retake a capture on.
    var deviceName: String {
        switch self {
        case .iPhone: "iPhone 17 Pro Max"
        case .iPad: "iPad Pro 13-inch (M5)"
        case .mac: "Mac"
        case .watch: "Apple Watch Ultra"
        case .appleTV: "Apple TV 4K"
        case .visionPro: "Apple Vision Pro"
        }
    }

    /// The pixel size in portrait (short side first). Landscape swaps them.
    var portraitPixelSize: PixelSize {
        switch self {
        case .iPhone: PixelSize(width: 1320, height: 2868)
        case .iPad: PixelSize(width: 2064, height: 2752)
        case .mac: PixelSize(width: 2880, height: 1800)
        case .watch: PixelSize(width: 422, height: 514)
        case .appleTV: PixelSize(width: 3840, height: 2160)
        case .visionPro: PixelSize(width: 3840, height: 2160)
        }
    }

    /// The device class whose captures belong in this set: an iPad capture
    /// in an iPhone slot fails the capture-size check.
    var isTablet: Bool { self == .iPad }

    /// The display type a set of App Store Connect counts as, if it's one
    /// AppLocalizer knows. Smaller iPhone and iPad sizes aren't templates'
    /// business and return nil.
    init?(apiValue: String) {
        self.init(rawValue: apiValue)
    }
}
