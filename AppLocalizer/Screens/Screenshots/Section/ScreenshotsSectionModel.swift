//
//  ScreenshotsSectionModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The Screenshots section (⌘4) of one app: reads the version Store Page
/// would show (the newest editable one, else the live one) and keeps the
/// screenshots model on it, with the store texts the App Store preview
/// draws.
@MainActor
@Observable
final class ScreenshotsSectionModel {
    let app: StoreApp
    let services: any StorePageServices
    private(set) var content: StorePageContent?
    private(set) var screenshots: ScreenshotsViewModel?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    @ObservationIgnored private weak var push: PushController?

    init(app: StoreApp, services: any StorePageServices, push: PushController? = nil) {
        self.app = app
        self.services = services
        self.push = push
    }

    /// Reads the version's texts and IDs, then makes the screenshots model
    /// the first time, or moves it to another version, or reloads it.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await services.content(for: app, versionID: nil)
            content = loaded
            errorMessage = nil
            var context = ScreenshotsContext(content: loaded)
            await context.readPlatformLocalizations(in: loaded) { [app, services] id in
                try await services.content(for: app, versionID: id)
            }
            await context.readWatchApp { [app, services] id in
                try await services.hasWatchApp(for: app, versionID: id)
            }
            if let screenshots {
                if context != screenshots.context {
                    await screenshots.update(context: context)
                } else if screenshots.isLoaded {
                    await screenshots.load()
                }
            } else {
                let screenshots = ScreenshotsViewModel(app: app, services: services.screenshots, context: context)
                screenshots.tab = services.screenshots.initialTab
                screenshots.showsLanguagePage = services.screenshots.opensLanguagePage
                self.screenshots = screenshots
            }
            screenshots?.studio.storeTexts = StudioStoreTexts(content: loaded)
        } catch {
            errorMessage = StorePageErrorReporter.report(error, to: push)
        }
    }
}
