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
    var secrets: any SecretStore = KeychainSecretStore()

    /// The rating App Store Connect shows and whether App Review has what
    /// it needs. App Privacy has no API: its status comes with part 2's
    /// worksheet, so it reads Not started here.
    func summary(for app: StoreApp) async throws -> AppInformationSummary {
        let content = try await content(for: app, versionID: nil)
        return AppInformationSummary(
            ageRating: content.ageRating.currentRating,
            privacyStatus: .notStarted,
            isAppReviewComplete: content.review.isComplete
        )
    }

    func content(for app: StoreApp, versionID: String?) async throws -> AppInformationContent {
        try await AppInformationContentLoader(client: client).content(for: app, versionID: versionID)
    }

    func accessibility(for app: StoreApp) async throws -> AccessibilityContent {
        try await AccessibilityContentLoader(client: client).content(for: app)
    }
}
