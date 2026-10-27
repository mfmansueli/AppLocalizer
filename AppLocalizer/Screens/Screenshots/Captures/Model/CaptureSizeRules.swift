//
//  CaptureSizeRules.swift
//  AppLocalizer
//

import Foundation

/// Which set a capture belongs in, from its pixel size and the device it
/// was taken on, and whether its size suits that set. The 6.9″ iPhone set
/// takes the large iPhones' captures (1260–1320 px wide); a 6.1″ capture
/// would be scaled up, so the person decides. iPads go in the 13″ set.
enum CaptureSizeRules {
    /// Long side ÷ short side below this is an iPad's.
    static let tabletAspectLimit = 1.7

    /// The smallest short side each set takes as it is.
    static func smallestWidth(for display: ScreenshotDisplayType) -> Int {
        display.isTablet ? 1960 : 1254
    }

    /// The set a capture goes in: the device name says iPhone or iPad,
    /// else the size's aspect does. Nil without either.
    static func displayType(pixelSize: PixelSize?, deviceName: String?) -> ScreenshotDisplayType? {
        let name = deviceName?.lowercased() ?? ""
        if name.contains("ipad") { return .iPad }
        if name.contains("iphone") { return .iPhone }
        guard let pixelSize, pixelSize.width > 0, pixelSize.height > 0 else { return nil }
        return pixelSize.aspectRatio < tabletAspectLimit ? .iPad : .iPhone
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
