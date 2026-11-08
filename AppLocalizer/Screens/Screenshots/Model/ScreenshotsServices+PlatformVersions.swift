//
//  ScreenshotsServices+PlatformVersions.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsServices {
    /// What's live in the version's localizations, plus the Apple Vision
    /// Pro sets of the visionOS version's and the Mac sets of the macOS
    /// version's, when the app has them.
    func liveScreenshots(for app: StoreApp, context: ScreenshotsContext) async throws -> LiveScreenshots {
        var live = try await liveScreenshots(for: app, localizations: context.localizations)
        for (display, localizations) in [(ScreenshotDisplayType.visionPro, context.visionLocalizations), (.mac, context.macLocalizations)] {
            guard !localizations.isEmpty else { continue }
            let other = try await liveScreenshots(for: app, localizations: localizations)
            live.screenshotSets.removeAll { $0.displayType == display }
            live.previewSets.removeAll { $0.displayType == display }
            live.screenshotSets += other.screenshotSets.filter { $0.displayType == display }
            live.previewSets += other.previewSets.filter { $0.displayType == display }
        }
        return live
    }
}
