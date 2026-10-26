//
//  ScreenshotsSnapshot.swift
//  AppLocalizer
//

import Foundation

/// The inputs to the Sets matrix at one moment: the app's document, what's
/// live in App Store Connect, its locales and the version screenshots
/// would go with.
struct ScreenshotsSnapshot: Hashable, Sendable {
    var document: ScreenshotsDocument
    var live: LiveScreenshots
    var primaryLocale: StoreLocale
    /// Every locale a row can show, in App Store Connect's order.
    var locales: [StoreLocale]
    var version: ScreenshotsVersion
    var fonts: ScreenshotFontCatalog = .standard

    func locale(code: String) -> StoreLocale? {
        locales.first { $0.code == code } ?? StoreLocaleCatalog.locale(code: code)
    }
}
