//
//  ScreenshotDisplayType.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A set of App Store screenshots for one kind of device. iPhone 6.9″ and
/// iPad 13″ are the sizes Apple requires and templates are designed for;
/// the App Store scales them down for smaller devices. iPhone Duo, the
/// foldable, is rendered from the template too, at its inner display's
/// size (one App Store Connect set takes the inner and the outer display's
/// screenshots); Apple requires it from April 2027. Apple Watch (the
/// captures themselves, no captions) and Apple Vision Pro (the template's
/// headline over the capture in a window) have screens of their own, made
/// by Screenshot Autopilot. Mac and Apple TV are listed so the model is
/// visibly open to them.
enum ScreenshotDisplayType: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case iPhone = "APP_IPHONE_67"
    /// Not in Apple's published API spec yet; App Store Connect takes it.
    case iPhoneDuo = "APP_IPHONE_DUO"
    case iPad = "APP_IPAD_PRO_3GEN_129"
    case mac = "APP_DESKTOP"
    case watch = "APP_WATCH_ULTRA"
    case appleTV = "APP_APPLE_TV"
    case visionPro = "APP_APPLE_VISION_PRO"

    var id: String { rawValue }

    /// The display types templates are designed for, in menu order: they
    /// share the set's slots and captions.
    static let rendered: [ScreenshotDisplayType] = [.iPhone, .iPhoneDuo, .iPad]

    var isRendered: Bool { Self.rendered.contains(self) }

    /// Every device the Screenshots section previews and Autopilot plans.
    static let studio: [ScreenshotDisplayType] = [.iPhone, .iPhoneDuo, .iPad, .watch, .visionPro]

    /// Devices with screens of their own instead of the set's slots.
    static let ownScreens: [ScreenshotDisplayType] = [.watch, .visionPro]

    var hasOwnScreens: Bool { Self.ownScreens.contains(self) }

    /// Screenshots of this device carry a caption. Apple Watch's are the
    /// captures themselves: the watch screen is too small for one.
    var hasCaptions: Bool { self != .watch }

    /// When Apple starts requiring it, for a device it doesn't require
    /// yet: "Required from April 2027 for apps built with the iOS 27.1 SDK".
    var upcomingRequirement: String? {
        self == .iPhoneDuo ? String(localized: "Required from April 2027 for apps built with the iOS 27.1 SDK") : nil
    }

    /// App Store Connect's `screenshotDisplayType`.
    var apiValue: String { rawValue }

    /// App Store Connect's `previewType` for App Previews of the same size.
    var previewType: String? {
        switch self {
        case .iPhone: "IPHONE_67"
        case .iPhoneDuo: "IPHONE_DUO"
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
        case .iPhoneDuo: String(localized: "iPhone Duo")
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
        case .iPhoneDuo: "iPhone Duo"
        case .iPad: "iPad Pro 13-inch (M5)"
        case .mac: "Mac"
        case .watch: "Apple Watch Ultra 3 (49mm)"
        case .appleTV: "Apple TV 4K"
        case .visionPro: "Apple Vision Pro"
        }
    }

    /// The pixel size in portrait (short side first). Landscape swaps them;
    /// Apple Vision Pro is always landscape (3840 × 2160). iPhone Duo's is
    /// its inner display's, unfolded.
    var portraitPixelSize: PixelSize {
        switch self {
        case .iPhone: PixelSize(width: 1320, height: 2868)
        case .iPhoneDuo: PixelSize(width: 2007, height: 2853)
        case .iPad: PixelSize(width: 2064, height: 2752)
        case .mac: PixelSize(width: 2880, height: 1800)
        case .watch: PixelSize(width: 422, height: 514)
        case .appleTV: PixelSize(width: 3840, height: 2160)
        case .visionPro: PixelSize(width: 2160, height: 3840)
        }
    }

    /// The size its screenshots are: landscape on Apple Vision Pro, else
    /// portrait.
    var defaultPixelSize: PixelSize {
        self == .visionPro ? portraitPixelSize.rotated : portraitPixelSize
    }

    /// The device class whose captures belong in this set: an iPad capture
    /// in an iPhone slot fails the capture-size check.
    var isTablet: Bool { self == .iPad }

    /// "iphone", "ipad" or "rectangle.split.2x1" (iPhone Duo, unfolded).
    var symbolName: String {
        switch self {
        case .iPad: "ipad"
        case .iPhoneDuo: "rectangle.split.2x1"
        case .watch: "applewatch"
        case .visionPro: "visionpro"
        case .mac: "desktopcomputer"
        case .appleTV: "appletv"
        case .iPhone: "iphone"
        }
    }

    /// A thumbnail's width given an iPhone's and an iPad's: iPhone Duo's
    /// wider inner display at the iPhone's height sits between them.
    func thumbnailWidth(phone: CGFloat, tablet: CGFloat) -> CGFloat {
        switch self {
        case .iPad: tablet
        case .iPhoneDuo: (phone * Self.duoWidthBesideIPhone).rounded()
        default: phone
        }
    }

    /// How much wider iPhone Duo's portrait screenshot is than an iPhone's
    /// of the same height: about 1.53.
    private static var duoWidthBesideIPhone: CGFloat {
        let duo = iPhoneDuo.portraitPixelSize
        let phone = iPhone.portraitPixelSize
        return (CGFloat(duo.width) / CGFloat(duo.height)) / (CGFloat(phone.width) / CGFloat(phone.height))
    }

    /// The display type a set of App Store Connect counts as, if it's one
    /// AppLocalizer knows. Smaller iPhone and iPad sizes aren't templates'
    /// business and return nil.
    init?(apiValue: String) {
        self.init(rawValue: apiValue)
    }
}
