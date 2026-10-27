//
//  ScreenshotPlanInput.swift
//  AppLocalizer
//

import Foundation

/// Everything a screenshot push plan is derived from, for one app.
struct ScreenshotPlanInput: Sendable {
    var appID: StoreApp.ID
    var appName: String
    var document: ScreenshotsDocument
    var live: LiveScreenshots
    var context: ScreenshotsContext
    /// Every App Store locale, in App Store Connect's order.
    var locales: [StoreLocale] = StoreLocaleCatalog.all
    var fonts: ScreenshotFontCatalog = .standard
    /// Discards and restores waiting.
    var state = ScreenshotPushState()

    var snapshot: ScreenshotsSnapshot {
        ScreenshotsSnapshot(
            document: document, live: live, primaryLocale: context.primaryLocale, locales: locales, version: context.version, fonts: fonts
        )
    }
}
