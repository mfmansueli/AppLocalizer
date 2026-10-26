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

    func screenshots(for app: StoreApp, content _: StorePageContent) async throws -> ScreenshotCoverage {
        if let error { throw error }
        return app.id == DebugFixtures.AppID.lumen
            ? StorePageSampleData.screenshots
            : ScreenshotCoverage(primaryLocale: .englishUS, counts: [:])
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
