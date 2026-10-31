//
//  AutopilotContext.swift
//  AppLocalizer
//

import Foundation

/// What a run needs to touch the app's screenshots: the app, the
/// screenshot services (document, captures, fonts) and the primary
/// language. The Screenshots section and the assistant tools each make one.
@MainActor
struct AutopilotContext {
    var app: StoreApp
    var services: any ScreenshotsServices
    var primaryLocale: StoreLocale
}
