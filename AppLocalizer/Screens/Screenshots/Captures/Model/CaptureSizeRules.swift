//
//  CaptureSizeRules.swift
//  AppLocalizer
//

import Foundation

/// Which set a capture belongs in, from its pixel size and the device it
/// was taken on, and whether its size suits that set. The 6.9″ iPhone set
/// takes the large iPhones' captures (1260–1320 px wide); a 6.1″ capture
/// would be scaled up, so the person decides. iPads go in the 13″ set.
/// iPhone Duo's displays have sizes of their own, and App Store Connect's
/// iPhone Duo set takes both: the inner display's (2007 × 2853) and the
/// outer one's (1398 × 2034), either way up.
enum CaptureSizeRules {
    /// Long side ÷ short side below this is an iPad's.
    static let tabletAspectLimit = 1.7

    /// iPhone Duo's inner display, unfolded, in portrait.
    static let duoInnerSize = PixelSize(width: 2007, height: 2853)
    /// iPhone Duo's outer display, in portrait.
    static let duoOuterSize = PixelSize(width: 1398, height: 2034)
    /// Both of iPhone Duo's screens. No iPhone or iPad has either size.
    static let duoSizes = [duoInnerSize, duoOuterSize]

    /// A capture of iPhone Duo's outer display, either way up.
    static func isDuoOuterDisplay(_ size: PixelSize) -> Bool {
        size == duoOuterSize || size == duoOuterSize.rotated
    }

    /// The smallest short side each set takes as it is: iPhone Duo's is
    /// its outer display's.
    static func smallestWidth(for display: ScreenshotDisplayType) -> Int {
        switch display {
        case .iPad: 1960
        case .iPhoneDuo: 1398
        default: 1254
        }
    }

    /// The set a capture goes in: the device name says iPhone Duo, iPad or
    /// iPhone, else the size does. Nil without either.
    static func displayType(pixelSize: PixelSize?, deviceName: String?) -> ScreenshotDisplayType? {
        let name = deviceName?.lowercased() ?? ""
        if name.contains("duo") { return .iPhoneDuo }
        if name.contains("ipad") { return .iPad }
        if name.contains("iphone") { return .iPhone }
        guard let pixelSize, pixelSize.width > 0, pixelSize.height > 0 else { return nil }
        return deviceClass(of: pixelSize)
    }

    /// The device a capture of this size was taken on: iPhone Duo by its
    /// exact sizes, else iPad or iPhone by the aspect.
    static func deviceClass(of size: PixelSize) -> ScreenshotDisplayType {
        if duoSizes.contains(where: { $0 == size || $0.rotated == size }) { return .iPhoneDuo }
        return size.aspectRatio < tabletAspectLimit ? .iPad : .iPhone
    }

    /// Whether a capture of this size is from the device `display`'s set is
    /// for. Only the sets templates render have a device class.
    static func isSameDevice(_ size: PixelSize, as display: ScreenshotDisplayType) -> Bool {
        deviceClass(of: size) == display
    }

    /// Whether `size` goes in `display`'s set without scaling.
    static func fits(_ size: PixelSize, in display: ScreenshotDisplayType) -> Bool {
        min(size.width, size.height) >= smallestWidth(for: display)
    }

    /// How much a smaller capture is scaled up to fill the set's canvas:
    /// 1.13 for a 1170 px wide capture in the 1320 px iPhone set.
    static func scale(of size: PixelSize, in display: ScreenshotDisplayType) -> Double {
        let short = Double(min(size.width, size.height))
        return short > 0 ? Double(display.portraitPixelSize.width) / short : 1
    }
}
