//
//  ScreenshotsSnapshot.swift
//  AppLocalizer
//

import Foundation

/// The inputs to the Sets matrix at one moment: the app's document, what's
/// live in App Store Connect, its locales, the version screenshots would
/// go with and the App Store ratings the template's laurels are checked
/// against.
struct ScreenshotsSnapshot: Hashable, Sendable {
    var document: ScreenshotsDocument
    var live: LiveScreenshots
    var primaryLocale: StoreLocale
    /// Every locale a row can show, in App Store Connect's order.
    var locales: [StoreLocale]
    var version: ScreenshotsVersion
    var fonts: ScreenshotFontCatalog = .standard
    var ratings: StoreRatings = .unchecked

    func locale(code: String) -> StoreLocale? {
        locales.first { $0.code == code } ?? StoreLocaleCatalog.locale(code: code)
    }
}
