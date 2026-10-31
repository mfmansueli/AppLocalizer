//
//  DebugStorePageServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `StorePageServices` for DEBUG scenes: the sample apps' canned data
/// (`DebugStorePageContent`), optionally failing with `error` or slowed by
/// `delay`. Never contacts App Store Connect.
///
/// `opening` puts the section in a scene's state once it has loaded: a
/// view, a locale, an open sheet. It runs once per scene, so navigating
/// away and back behaves normally.
@MainActor
struct DebugStorePageServices: StorePageServices {
    var error: AppStoreConnectError?
    /// How long loading the store page takes.
    var delay: Duration?
    /// False for the "No version to edit" scene: only 1.3 is live.
    var hasEditableVersion = true
    var translator: any ListingTranslator = DebugListingTranslator()
    var machineTranslations: any MachineTranslationStore = InMemoryMachineTranslationStore(
        storage: DebugStorePageContent.machineTranslationTags
    )
    var opening: Opening?
    /// Lumen's sample screenshots (`ScreenshotsSampleData`).
    var screenshots: any ScreenshotsServices = DebugScreenshotsServices()
    /// What Lumen's project supports; nil hides new languages.
    var appSupport: AppSupportCenter?
    /// The version's build has an Apple Watch app, as App Store Connect
    /// would say once one is attached.
    var buildHasWatchApp = false

    func hasWatchApp(for _: StoreApp, versionID _: String) async throws -> Bool { buildHasWatchApp }

    func summary(for app: StoreApp) async throws -> StorePageSummary {
        if let error { throw error }
        return DebugSummaries.storePage(for: app.id)
    }

    func content(for app: StoreApp, versionID: String?) async throws -> StorePageContent {
        if let delay { try await Task.sleep(for: delay) }
        if let error { throw error }
        guard app.id == DebugFixtures.AppID.lumen else {
            return DebugStorePageContent.released(appName: app.name, versionString: DebugSummaries.storePage(for: app.id).versionString ?? "1.0")
        }
        return DebugStorePageContent.lumen(versionID: versionID, hasEditableVersion: hasEditableVersion)
    }

    func inAppTexts(for app: StoreApp) async throws -> InAppTextsContent {
        if let error { throw error }
        return app.id == DebugFixtures.AppID.lumen ? DebugStorePageContent.inAppTexts : .empty
    }

    /// Lumen's reviews for Generate Suggestions…: a handful of kinds,
    /// repeated up to `limit`.
    func customerReviews(for app: StoreApp, limit: Int) async throws -> [CustomerReview] {
        if let error { throw error }
        guard app.id == DebugFixtures.AppID.lumen else { return [] }
        let kinds = [
            CustomerReview(rating: 5, title: "Finally private", body: "I write every night and nothing leaves my phone."),
            CustomerReview(rating: 5, title: "Calm", body: "The prompts help on days I don’t know what to write."),
            CustomerReview(rating: 4, title: "Love the mood tags", body: "Search could be faster with years of entries."),
            CustomerReview(rating: 3, title: "Sync", body: "iCloud sync is slow on my old iPad."),
        ]
        return (0..<min(limit, 220)).map { kinds[$0 % kinds.count] }
    }

    /// Runs a scene's setup once, on the first view model that loads.
    @MainActor
    final class Opening {
        private var setUp: (@MainActor (StorePageViewModel) async -> Void)?

        init(_ setUp: @escaping @MainActor (StorePageViewModel) async -> Void) {
            self.setUp = setUp
        }

        func run(on viewModel: StorePageViewModel) async {
            guard let setUp else { return }
            self.setUp = nil
            await setUp(viewModel)
        }
    }
}
#endif
