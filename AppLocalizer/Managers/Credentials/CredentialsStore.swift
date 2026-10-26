//
//  CredentialsStore.swift
//  AppLocalizer
//

import Foundation

/// Where the API key is kept between launches. `KeychainCredentialsStore` is
/// the real one; DEBUG scenes and tests use in-memory stores, so they never
/// read or overwrite the key in the login Keychain.
protocol CredentialsStore {
    /// nil when no key has been saved yet.
    func load() throws -> AppStoreConnectCredentials?
    func save(_ credentials: AppStoreConnectCredentials) throws
    /// Removing a key that isn't there succeeds.
    func delete() throws
}
