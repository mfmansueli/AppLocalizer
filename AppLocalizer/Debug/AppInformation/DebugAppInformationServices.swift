//
//  DebugAppInformationServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `AppInformationServices` for DEBUG scenes: the sample apps' canned data
/// (`DebugAppInformationContent`), optionally failing with `error` or
/// slowed by `delay`, and the same for accessibility on its own. Never
/// contacts App Store Connect; notes, App Privacy worksheets and the demo
/// password stay in memory.
///
/// `opening` puts the section in a scene's state once it has loaded: a
/// page, an open sheet or popover. It runs once per scene.
@MainActor
struct DebugAppInformationServices: AppInformationServices {
    var error: AppStoreConnectError?
    var delay: Duration?
    var accessibilitySample = DebugAppInformationContent.AccessibilitySample.lumen
    var accessibilityError: AppStoreConnectError?
    var accessibilityDelay: Duration?
    var privacyURLsError: AppStoreConnectError?
    /// Lumen's 1.4 still says © 2025 and has no contact phone, which 1.3's
    /// App Review details had: what the built-in suggestions find.
    var hasOutdatedDetails = false
    let notes: any AppInformationNotesStore
    let privacy: any PrivacyWorksheetStore
    let secrets: any SecretStore
    var opening: Opening?

    init(
        error: AppStoreConnectError? = nil,
        delay: Duration? = nil,
        accessibilitySample: DebugAppInformationContent.AccessibilitySample = .lumen,
        accessibilityError: AppStoreConnectError? = nil,
        accessibilityDelay: Duration? = nil,
        privacy worksheet: PrivacyWorksheet = DebugPrivacyWorksheets.overview
    ) {
        self.error = error
        self.delay = delay
        self.accessibilitySample = accessibilitySample
        self.accessibilityError = accessibilityError
        self.accessibilityDelay = accessibilityDelay
        notes = InMemoryAppInformationNotesStore([DebugFixtures.AppID.lumen: DebugAppInformationContent.notes])
        privacy = InMemoryPrivacyWorksheetStore([DebugFixtures.AppID.lumen: worksheet])
        secrets = InMemorySecretStore()
    }

    /// The sample summary, with App Privacy from this scene's worksheet and
    /// the privacy URLs' coverage.
    func summary(for app: StoreApp) async throws -> AppInformationSummary {
        if let error { throw error }
        var summary = DebugSummaries.appInformation(for: app.id)
        summary.privacy = AppInformationSummary.Privacy(worksheet: privacy.worksheet(for: app.id))
        if let urls = try? await privacyURLs(for: app) {
            summary.privacyURLs = AppInformationSummary.PrivacyURLs(table: PrivacyURLsTable(appID: app.id, content: urls, changes: []))
        }
        return summary
    }

    func privacyURLs(for app: StoreApp) async throws -> PrivacyURLsContent {
        if let privacyURLsError { throw privacyURLsError }
        return DebugAppInformationContent.privacyURLs(for: app)
    }

    func content(for app: StoreApp, versionID: String?) async throws -> AppInformationContent {
        if let delay { try await Task.sleep(for: delay) }
        if let error { throw error }
        guard app.id == DebugFixtures.AppID.lumen else {
            return DebugAppInformationContent.released(app, versionString: DebugSummaries.storePage(for: app.id).versionString ?? "1.0")
        }
        var content = DebugAppInformationContent.lumen(versionID: versionID)
        if hasOutdatedDetails, content.isVersionEditable {
            content.general.copyright = "© 2025 Northpier Studio"
            content.general.release = .manual
            content.review.phone = ""
        }
        return content
    }

    func previousReview(for app: StoreApp, content: AppInformationContent) async -> AppInformationBuiltInSuggestions.PreviousReview? {
        guard app.id == DebugFixtures.AppID.lumen, content.isVersionEditable else { return nil }
        return AppInformationBuiltInSuggestions.PreviousReview(versionString: "1.3", review: DebugAppInformationContent.review)
    }

    func accessibility(for app: StoreApp) async throws -> AccessibilityContent {
        if let accessibilityDelay { try await Task.sleep(for: accessibilityDelay) }
        if let accessibilityError { throw accessibilityError }
        guard app.id == DebugFixtures.AppID.lumen else { return DebugAppInformationContent.releasedAccessibility() }
        return DebugAppInformationContent.accessibility(accessibilitySample)
    }

    /// Runs a scene's setup once, on the first view model that loads.
    @MainActor
    final class Opening {
        private var setUp: (@MainActor (AppInformationViewModel) async -> Void)?

        init(_ setUp: @escaping @MainActor (AppInformationViewModel) async -> Void) {
            self.setUp = setUp
        }

        func run(on viewModel: AppInformationViewModel) async {
            guard let setUp else { return }
            self.setUp = nil
            await setUp(viewModel)
        }
    }
}
#endif
