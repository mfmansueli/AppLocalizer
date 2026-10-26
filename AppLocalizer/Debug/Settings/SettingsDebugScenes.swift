//
//  SettingsDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import CryptoKit
import SwiftUI

/// Settings DEBUG scenes (`-AppLocalizerDebugScene <id>`): `set-account`,
/// `set-pricing`, `set-translation` and `set-general` open the real Settings
/// window on that tab, with the design's two saved keys (Northpier Studio
/// in use, Brightline Apps without Sales and Trends) and its glossary. The
/// main window closes, so the Settings window is the only one.
enum SettingsDebugScenes {
    static let ids = ["set-account", "set-pricing", "set-translation", "set-general"]

    static let brightlineIssuerID = "5e1f0a42-8d7b-4c19-9f6e-27b3d0c8e915"

    static func tab(for id: String) -> SettingsTab? {
        switch id {
        case "set-account": .account
        case "set-pricing": .pricing
        case "set-translation": .translation
        case "set-general": .general
        default: nil
        }
    }

    /// The saved keys a scene starts with: both sample keys for Settings,
    /// none elsewhere (the connect scenes start empty).
    static func credentialsStore(for id: String) -> DebugCredentialsStore {
        guard ids.contains(id) else { return DebugCredentialsStore() }
        return DebugCredentialsStore(keys: [
            AppStoreConnectCredentials(
                issuerID: DebugFixtures.issuerID,
                keyID: DebugFixtures.northpier.keyID,
                privateKeyPEM: P256.Signing.PrivateKey().pemRepresentation,
                teamName: DebugFixtures.northpier.name
            ),
            AppStoreConnectCredentials(
                issuerID: brightlineIssuerID,
                keyID: DebugFixtures.brightline.keyID,
                privateKeyPEM: P256.Signing.PrivateKey().pemRepresentation,
                teamName: DebugFixtures.brightline.name
            ),
        ])
    }

    /// Translation shows a saved Anthropic key as dots.
    static func secretStore(for id: String) -> InMemorySecretStore {
        id == "set-translation" ? InMemorySecretStore(secrets: [AIProviderVendor.anthropic.secretName: "sk-ant-debug"]) : InMemorySecretStore()
    }

    @MainActor
    static func view(for id: String) -> AnyView? {
        ids.contains(id) ? AnyView(Opener()) : nil
    }

    /// Fills in what the design shows, opens Settings and closes the main
    /// window.
    private struct Opener: View {
        @Environment(AppSession.self) private var session
        @Environment(TranslationPreferences.self) private var translation
        @Environment(\.openSettings) private var openSettings
        @Environment(\.dismissWindow) private var dismissWindow

        var body: some View {
            Color.clear
                .task {
                    session.record(
                        KeyAccessCheck(appCount: DebugFixtures.apps.count, milliseconds: 182, salesAccess: .readable, date: .now),
                        for: DebugFixtures.northpier.keyID
                    )
                    session.record(
                        KeyAccessCheck(appCount: 3, milliseconds: 240, salesAccess: .notAllowed, date: .now),
                        for: DebugFixtures.brightline.keyID
                    )
                    translation.glossary = TranslationGlossary(terms: ["Lumen", "Lumen Plus", "Face ID", "iCloud", "Weekly Reflections"])
                    translation.sourceLocaleCode = "en-US"
                    openSettings()
                    dismissWindow(id: "main")
                }
        }
    }
}
#endif
