//
//  CredentialsStore.swift
//  AppLocalizer
//

import Foundation

/// Where saved API keys are kept between launches, one per key ID.
/// `KeychainCredentialsStore` is the real one; DEBUG scenes and tests use
/// in-memory stores, so they never read or overwrite keys in the login
/// Keychain.
protocol CredentialsStore {
    /// Every saved key, oldest first; empty before the first one is saved.
    func loadAll() throws -> [AppStoreConnectCredentials]
    /// Adds a key, or replaces the saved key with the same key ID.
    func save(_ credentials: AppStoreConnectCredentials) throws
    /// Removing a key that isn't there succeeds.
    func delete(keyID: String) throws
}
