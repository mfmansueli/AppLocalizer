//
//  ScreenshotPushWorkspace.swift
//  AppLocalizer
//

import Foundation

/// The account a screenshot push works in: its services and its apps.
/// The main window attaches it (`MainView.configurePush`).
struct ScreenshotPushWorkspace {
    /// Identifies the account, so switching accounts starts over.
    var teamName: String
    var services: WorkspaceServices
    var apps: @MainActor () async throws -> [StoreApp]

    @MainActor
    var screenshots: any ScreenshotsServices { services.screenshots }

    /// Nil when these services can't push screenshots.
    @MainActor
    var pushing: (any ScreenshotPushServices)? {
        (screenshots as? any ScreenshotPushProviding)?.pushing
    }
}
