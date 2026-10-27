//
//  DebugPrivacyURLChanges.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen Journal's queued privacy URL edits, built by the Privacy URLs
/// tab's own table so they're the changes the tab makes.
enum DebugPrivacyURLChanges {
    /// French (Canada)'s Privacy Policy URL, which was missing.
    static var frenchCanadaPolicy: PendingChange? {
        policy(.frenchCanada, "https://lumen.example/fr/confidentialite")
    }

    /// Hebrew's Privacy Policy URL, which was missing.
    static var hebrewPolicy: PendingChange? {
        policy(.hebrew, "https://lumen.example/he/privacy")
    }

    /// French (Canada)'s User Privacy Choices URL.
    static var frenchCanadaChoices: PendingChange? {
        table.choicesChange(.frenchCanada, to: "https://lumen.example/fr/choix").change
    }

    private static var table: PrivacyURLsTable {
        let app = DebugFixtures.lumen
        return PrivacyURLsTable(appID: app.id, content: DebugAppInformationContent.privacyURLs(for: app), changes: [])
    }

    private static func policy(_ locale: StoreLocale, _ url: String) -> PendingChange? {
        table.policyChange(locale, to: url).change
    }
}
#endif
