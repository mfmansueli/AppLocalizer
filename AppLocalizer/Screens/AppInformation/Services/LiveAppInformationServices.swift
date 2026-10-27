//
//  LiveAppInformationServices.swift
//  AppLocalizer
//

import Foundation

/// The real `AppInformationServices`, backed by App Store Connect. Requests
/// go one at a time, like the other sections'.
@MainActor
struct LiveAppInformationServices: AppInformationServices {
    let client: AppStoreConnectClient
    var notes: any AppInformationNotesStore = DefaultsAppInformationNotesStore.shared
    var privacy: any PrivacyWorksheetStore = FilePrivacyWorksheetStore.shared
    var secrets: any SecretStore = KeychainSecretStore()

    /// The rating App Store Connect shows, whether App Review has what it
    /// needs, the App Privacy worksheet kept on this Mac (App Privacy has no
    /// API), and how many locales have privacy URLs. URLs that can't be
    /// read leave their card out rather than failing the summary.
    func summary(for app: StoreApp) async throws -> AppInformationSummary {
        let content = try await content(for: app, versionID: nil)
        let urls = try? await privacyURLs(for: app)
        return AppInformationSummary(
            ageRating: content.ageRating.currentRating,
            privacy: AppInformationSummary.Privacy(worksheet: privacy.worksheet(for: app.id)),
            privacyURLs: urls.map { AppInformationSummary.PrivacyURLs(table: PrivacyURLsTable(appID: app.id, content: $0, changes: [])) },
            isAppReviewComplete: content.review.isComplete
        )
    }

    func content(for app: StoreApp, versionID: String?) async throws -> AppInformationContent {
        try await AppInformationContentLoader(client: client).content(for: app, versionID: versionID)
    }

    func accessibility(for app: StoreApp) async throws -> AccessibilityContent {
        try await AccessibilityContentLoader(client: client).content(for: app)
    }

    func privacyURLs(for app: StoreApp) async throws -> PrivacyURLsContent {
        try await PrivacyURLsLoader(client: client).content(for: app)
    }
}
