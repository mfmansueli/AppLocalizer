//
//  AppSession.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The saved App Store Connect keys and the one in use, shared by the main
/// window and the Settings window. `RootView` shows the connect screen while
/// no key is saved and the app library of `credentials` once one is.
@MainActor
@Observable
final class AppSession {
    /// Every saved key, oldest first.
    private(set) var keys: [AppStoreConnectCredentials] = []
    /// The key the main window uses.
    private(set) var currentKeyID: String?
    /// Set when the saved keys couldn't be read at launch; the connect screen
    /// shows it so the person knows why they're asked again.
    private(set) var loadErrorMessage: String?
    /// The last check of each key (Connect or "Test Connection"), by key ID.
    private(set) var checks: [String: KeyAccessCheck] = [:]
    /// A key that was just connected: the main window shows "Loading your
    /// apps…" until its library and summaries have loaded once.
    private(set) var firstSyncKeyID: String?
    /// "Add Another Key…" from the app menu or the account switcher shows
    /// the connect form in a sheet over the main window.
    var isAddingKey = false

    private let store: any CredentialsStore
    private let defaults: UserDefaults?

    /// `defaults` remembers the key in use and the checks; nil keeps them in
    /// memory (DEBUG scenes, tests).
    init(store: any CredentialsStore, defaults: UserDefaults? = nil) {
        self.store = store
        self.defaults = defaults
        do {
            keys = try store.loadAll()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
        if let data = defaults?.data(forKey: Key.checks),
           let saved = try? JSONDecoder().decode([String: KeyAccessCheck].self, from: data)
        {
            checks = saved.filter { id, _ in keys.contains { $0.keyID == id } }
        }
        let savedID = defaults?.string(forKey: Key.currentKeyID)
        currentKeyID = keys.contains { $0.keyID == savedID } ? savedID : keys.first?.keyID
    }

    // MARK: - Reading

    /// The key in use, or nil to show the connect screen.
    var credentials: AppStoreConnectCredentials? {
        keys.first { $0.keyID == currentKeyID }
    }

    /// The key in use as the account switcher shows it.
    var account: TeamAccount? { credentials.map(Self.account(for:)) }

    /// Every saved key, for the account switcher.
    var accounts: [TeamAccount] { keys.map(Self.account(for:)) }

    static func account(for credentials: AppStoreConnectCredentials) -> TeamAccount {
        TeamAccount(
            id: credentials.keyID,
            name: credentials.teamName ?? String(localized: "App Store Connect team"),
            role: String(localized: "Team key")
        )
    }

    // MARK: - Changing

    /// Saves an already-checked key (replacing a saved key with the same key
    /// ID), switches to it and starts its first sync.
    func connect(_ credentials: AppStoreConnectCredentials, check: KeyAccessCheck? = nil) throws {
        var credentials = credentials
        if credentials.teamName == nil {
            credentials.teamName = keys.first { $0.keyID == credentials.keyID }?.teamName
        }
        try store.save(credentials)
        if let index = keys.firstIndex(where: { $0.keyID == credentials.keyID }) {
            keys[index] = credentials
        } else {
            keys.append(credentials)
        }
        loadErrorMessage = nil
        isAddingKey = false
        if let check { record(check, for: credentials.keyID) }
        firstSyncKeyID = credentials.keyID
        setCurrentKeyID(credentials.keyID)
    }

    /// Switches the main window to another saved key.
    func select(keyID: String) {
        guard keyID != currentKeyID, keys.contains(where: { $0.keyID == keyID }) else { return }
        setCurrentKeyID(keyID)
    }

    /// Deletes a key from the Keychain. Removing the key in use switches to
    /// the oldest remaining one, or back to the connect screen.
    func remove(keyID: String) throws {
        try store.delete(keyID: keyID)
        keys.removeAll { $0.keyID == keyID }
        checks[keyID] = nil
        saveChecks()
        if firstSyncKeyID == keyID { firstSyncKeyID = nil }
        if currentKeyID == keyID { setCurrentKeyID(keys.first?.keyID) }
    }

    /// The API doesn't expose a team's name, so the person names each key.
    /// An empty name goes back to the default.
    func rename(keyID: String, to name: String) throws {
        guard let index = keys.firstIndex(where: { $0.keyID == keyID }) else { return }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var credentials = keys[index]
        credentials.teamName = name.isEmpty ? nil : name
        try store.save(credentials)
        keys[index] = credentials
    }

    func record(_ check: KeyAccessCheck, for keyID: String) {
        checks[keyID] = check
        saveChecks()
    }

    /// The main window calls this once the new key's library has loaded.
    func finishFirstSync() {
        firstSyncKeyID = nil
    }

    private func setCurrentKeyID(_ keyID: String?) {
        currentKeyID = keyID
        defaults?.set(keyID, forKey: Key.currentKeyID)
    }

    private func saveChecks() {
        guard let defaults, let data = try? JSONEncoder().encode(checks) else { return }
        defaults.set(data, forKey: Key.checks)
    }

    private enum Key {
        static let currentKeyID = "currentKeyID"
        static let checks = "keyAccessChecks"
    }
}
