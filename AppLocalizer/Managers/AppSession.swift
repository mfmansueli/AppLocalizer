//
//  AppSession.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The connected App Store Connect account, shared by the main window and
/// the Settings window. `RootView` shows the connect screen while
/// `credentials` is nil and the app library once it's set.
@MainActor
@Observable
final class AppSession {
    private(set) var credentials: AppStoreConnectCredentials?
    /// Set when the saved key couldn't be read at launch; the connect screen
    /// shows it so the person knows why they're asked again.
    private(set) var loadErrorMessage: String?

    /// The connected key as the account switcher shows it.
    var account: TeamAccount? {
        credentials.map {
            TeamAccount(
                id: $0.keyID,
                name: $0.teamName ?? String(localized: "App Store Connect team"),
                role: String(localized: "Team key")
            )
        }
    }

    /// Every saved key. One for now; the switcher lists them all.
    var accounts: [TeamAccount] { account.map { [$0] } ?? [] }

    private let store: any CredentialsStore

    init(store: any CredentialsStore) {
        self.store = store
        do {
            credentials = try store.load()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    /// Saves an already-verified key and switches to the app library.
    func connect(_ credentials: AppStoreConnectCredentials) throws {
        try store.save(credentials)
        self.credentials = credentials
        loadErrorMessage = nil
    }

    /// Forgets the key (Settings → Account → Remove) and goes back to the
    /// connect screen.
    func disconnect() throws {
        try store.delete()
        credentials = nil
    }
}
