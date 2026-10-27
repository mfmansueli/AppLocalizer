//
//  AppInformationServices.swift
//  AppLocalizer
//

import Foundation

/// What the App Information section needs from outside itself. `LiveAppInformationServices`
/// talks to App Store Connect; tests and DEBUG scenes use canned data.
@MainActor
protocol AppInformationServices {
    /// The numbers the overview cards and the sidebar show for one app.
    func summary(for app: StoreApp) async throws -> AppInformationSummary

    /// General, Age Rating, App Review and Export Compliance for the version
    /// with `versionID`, or the newest editable one (else the live one).
    func content(for app: StoreApp, versionID: String?) async throws -> AppInformationContent

    /// The accessibility declarations, the families they're for and the
    /// accessibility URL.
    func accessibility(for app: StoreApp) async throws -> AccessibilityContent

    /// Each locale's Privacy Policy URL and User Privacy Choices URL.
    func privacyURLs(for app: StoreApp) async throws -> PrivacyURLsContent

    /// What App Information keeps on this Mac (override reason, export
    /// answers, assistants' evidence).
    var notes: any AppInformationNotesStore { get }

    /// The App Privacy worksheets. App Store Connect has no API for the
    /// questionnaire, so they're only kept on this Mac.
    var privacy: any PrivacyWorksheetStore { get }

    /// Where the demo account's password is kept: the Keychain.
    var secrets: any SecretStore { get }
}
