//
//  LiveScreenshots.swift
//  AppLocalizer
//

import Foundation

/// What the version shows in App Store Connect right now: screenshot sets
/// and App Preview sets per locale and display type.
struct LiveScreenshots: Codable, Hashable, Sendable {
    var screenshotSets: [LiveScreenshotSet]
    var previewSets: [LiveAppPreviewSet]

    init(screenshotSets: [LiveScreenshotSet] = [], previewSets: [LiveAppPreviewSet] = []) {
        self.screenshotSets = screenshotSets
        self.previewSets = previewSets
    }

    func set(locale: String, displayType: ScreenshotDisplayType) -> LiveScreenshotSet? {
        screenshotSets.first { $0.locale == locale && $0.displayType == displayType && !$0.screenshots.isEmpty }
    }

    /// A set App Store Connect has here with nothing in it, left by an
    /// upload that never finished. It shows nothing, but creating another
    /// is refused ("Screenshot Set Already Exists"), so a push fills it.
    func emptySet(locale: String, displayType: ScreenshotDisplayType) -> LiveScreenshotSet? {
        screenshotSets.first { $0.locale == locale && $0.displayType == displayType && $0.screenshots.isEmpty }
    }

    func screenshot(locale: String, displayType: ScreenshotDisplayType, slot: Int) -> LiveScreenshot? {
        set(locale: locale, displayType: displayType)?.screenshot(slot: slot)
    }

    func previews(locale: String, displayType: ScreenshotDisplayType) -> LiveAppPreviewSet? {
        previewSets.first { $0.locale == locale && $0.displayType == displayType && $0.previewCount > 0 }
    }

    /// Whether `locale` has a screenshot set of its own on any display type.
    func hasOwnSet(locale: String) -> Bool {
        screenshotSets.contains { $0.locale == locale && !$0.screenshots.isEmpty }
    }
}
