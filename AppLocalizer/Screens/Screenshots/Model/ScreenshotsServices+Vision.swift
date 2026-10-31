//
//  ScreenshotsServices+Vision.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsServices {
    /// What's live in the version's localizations, plus the Apple Vision
    /// Pro sets of the visionOS version's, when the app has one.
    func liveScreenshots(for app: StoreApp, context: ScreenshotsContext) async throws -> LiveScreenshots {
        var live = try await liveScreenshots(for: app, localizations: context.localizations)
        guard !context.visionLocalizations.isEmpty else { return live }
        let vision = try await liveScreenshots(for: app, localizations: context.visionLocalizations)
        live.screenshotSets.removeAll { $0.displayType == .visionPro }
        live.screenshotSets += vision.screenshotSets.filter { $0.displayType == .visionPro }
        live.previewSets += vision.previewSets.filter { $0.displayType == .visionPro }
        return live
    }
}
