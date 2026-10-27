//
//  ScreenshotPushSummary.swift
//  AppLocalizer
//

import Foundation

/// What one screenshot push did for one app, as Activity lists it: how
/// many images went, which failed and why, the locales it touched and the
/// backup of the sets it replaced.
struct ScreenshotPushSummary: Codable, Hashable, Sendable {
    var pushedCount: Int
    /// "Chinese (Simplified) · iPhone · 1 Today: Upload timed out…".
    var failures: [String]
    /// Every locale the push sent images to, in push order.
    var locales: [String]
    /// The locales whose replaced screenshots were kept on this Mac.
    var keptLocales: [String]
    /// The backup holding them; nil when nothing was replaced.
    var backupID: String?
    /// The push put kept screenshots back.
    var isRestore: Bool

    var failedCount: Int { failures.count }
    var imageCount: Int { pushedCount + failedCount }

    /// "Screenshots · 80 images in 8 locales", or "Screenshots restored ·
    /// 10 images in 1 locale".
    var title: String {
        let images = imageCount == 1 ? String(localized: "1 image") : String(localized: "\(imageCount) images")
        let inLocales = locales.count == 1 ? String(localized: "1 locale") : String(localized: "\(locales.count) locales")
        if isRestore { return String(localized: "Screenshots restored · \(images) in \(inLocales)") }
        return String(localized: "Screenshots · \(images) in \(inLocales)")
    }

    /// "Kept on this Mac: the 3 sets this push replaced".
    var keptTitle: String {
        switch keptLocales.count {
        case 0: String(localized: "Nothing was replaced, so nothing was kept.")
        case 1: String(localized: "Kept on this Mac: the set this push replaced")
        default: String(localized: "Kept on this Mac: the \(keptLocales.count) sets this push replaced")
        }
    }
}
