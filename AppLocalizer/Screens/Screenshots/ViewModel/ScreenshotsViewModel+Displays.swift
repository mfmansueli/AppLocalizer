//
//  ScreenshotsViewModel+Displays.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsViewModel {
    /// The sets the template lays out for this app: iPhone, iPhone Duo and
    /// iPad, and Mac when the app runs there.
    var renderedDisplays: [ScreenshotDisplayType] {
        ScreenshotDisplayType.standard + (runsOnMac ? [.mac] : [])
    }

    /// The app has a macOS version, Mac captures or Mac screenshots live.
    var runsOnMac: Bool {
        context.hasMacVersion
            || document?.captures.hasCaptures(on: .mac) == true
            || live.screenshotSets.contains { $0.displayType == .mac && !$0.screenshots.isEmpty }
    }
}
