//
//  KeychainCredentialsStore.swift
//  AppLocalizer
//

import Foundation

/// Keeps each API key (issuer ID, key ID, the `.p8` contents and the team
/// name, as JSON) in its own login Keychain item, named by its key ID.
struct KeychainCredentialsStore: CredentialsStore {
    /// Before several keys could be saved, the one key lived under this
    /// account name. `loadAll()` moves it to its key ID.
    static let legacyAccount = "default"

    private let items: KeychainItems

    init(service: String = "AppLocalizer.AppStoreConnectAPIKey") {
        items = KeychainItems(service: service, label: "AppLocalizer — App Store Connect API key")
    }

    func loadAll() throws -> [AppStoreConnectCredentials] {
        try migrateLegacyItem()
        return try items.accounts().compactMap { account in
            try items.data(for: account).map { try JSONDecoder().decode(AppStoreConnectCredentials.self, from: $0) }
        }
    }

    func save(_ credentials: AppStoreConnectCredentials) throws {
        try items.set(JSONEncoder().encode(credentials), for: credentials.keyID)
    }

    func delete(keyID: String) throws {
        try items.delete(keyID)
    }

    /// Saves the single-key item under its key ID, then removes it.
    private func migrateLegacyItem() throws {
        guard let data = try items.data(for: Self.legacyAccount) else { return }
        try save(JSONDecoder().decode(AppStoreConnectCredentials.self, from: data))
        try items.delete(Self.legacyAccount)
    }
}
