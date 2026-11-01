//
//  AutopilotSupport.swift
//  AppLocalizer
//

import Foundation

/// What the app runs on and in, for a new plan: the devices beyond iPhone
/// (from the project's report; on App Store Connect, a visionOS version or
/// a build with a watch app; or live Apple Watch screenshots) and the
/// languages it supports that the App Store page doesn't have yet.
struct AutopilotSupport: Hashable, Sendable {
    var devices: Set<ScreenshotDisplayType> = []
    var newLocaleCodes: [String] = []

    static let none = AutopilotSupport()

    /// From the project's report, App Store Connect and what's live.
    @MainActor
    static func make(
        profile: AppSupportProfile?,
        declined: Set<String>,
        storeLocales: [String],
        hasVisionVersion: Bool,
        hasWatchApp: Bool = false,
        live: LiveScreenshots
    ) -> AutopilotSupport {
        var devices = Set(profile?.devices.map(\.displayType) ?? [])
        if hasVisionVersion { devices.insert(.visionPro) }
        if hasWatchApp { devices.insert(.watch) }
        let liveDevices = Set(live.screenshotSets.filter { !$0.screenshots.isEmpty }.map(\.displayType))
        for display in [ScreenshotDisplayType.iPhoneDuo, .watch, .visionPro] where liveDevices.contains(display) {
            devices.insert(display)
        }
        let new = (profile?.languagesMissing(from: storeLocales) ?? []).compactMap(\.storeLocale?.code).filter { !declined.contains($0) }
        return AutopilotSupport(devices: devices, newLocaleCodes: new)
    }
}
