//
//  StorePageServices.swift
//  AppLocalizer
//

import Foundation

/// What the Store Page section needs from outside itself. `LiveStorePageServices`
/// talks to App Store Connect; tests and DEBUG scenes use canned data.
@MainActor
protocol StorePageServices {
    /// The numbers the overview cards and the sidebar show for one app.
    func summary(for app: StoreApp) async throws -> StorePageSummary

    /// The app's versions and one version's texts in every locale: the one
    /// with `versionID`, or the newest editable one (else the live one).
    func content(for app: StoreApp, versionID: String?) async throws -> StorePageContent

    /// Subscription and in-app purchase names and descriptions.
    func inAppTexts(for app: StoreApp) async throws -> InAppTextsContent

    /// Screenshots: templates, captions, captures and the
    /// live screenshot sets.
    var screenshots: any ScreenshotsServices { get }

    /// Apple Translation, or a stand-in.
    var translator: any ListingTranslator { get }

    /// Where "machine-translated, not reviewed" is kept between launches.
    var machineTranslations: any MachineTranslationStore { get }

    /// The newest App Store reviews, for Generate Suggestions… when the
    /// person allowed them.
    func customerReviews(for app: StoreApp, limit: Int) async throws -> [CustomerReview]

    /// What each app's Xcode project supports (devices and languages), as
    /// its assistant reported it.
    var appSupport: AppSupportCenter? { get }

    /// Whether the build attached to the version has an Apple Watch app, so
    /// App Store Connect wants Apple Watch screenshots.
    func hasWatchApp(for app: StoreApp, versionID: String) async throws -> Bool
}

extension StorePageServices {
    func customerReviews(for _: StoreApp, limit _: Int) async throws -> [CustomerReview] { [] }

    var appSupport: AppSupportCenter? { nil }

    func hasWatchApp(for _: StoreApp, versionID _: String) async throws -> Bool { false }
}
