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

    /// How many screenshots each locale of the shown version has per size.
    func screenshots(for app: StoreApp, content: StorePageContent) async throws -> ScreenshotCoverage

    /// Apple Translation, or a stand-in.
    var translator: any ListingTranslator { get }

    /// Where "machine-translated, not reviewed" is kept between launches.
    var machineTranslations: any MachineTranslationStore { get }
}
