//
//  KeychainCredentialsStore.swift
//  AppLocalizer
//

import Foundation
import Security

/// Keeps the API key (issuer ID, key ID and the `.p8` contents, as JSON) in
/// one generic-password item of the login Keychain. It's the file-based
/// keychain, not the data-protection one: that one needs a provisioning
/// profile with a keychain access group, which a locally signed tool lacks.
struct KeychainCredentialsStore: CredentialsStore {
    var service = "AppLocalizer.AppStoreConnectAPIKey"
    var account = "default"

    func load() throws -> AppStoreConnectCredentials? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError(status: status) }
        return try JSONDecoder().decode(AppStoreConnectCredentials.self, from: data)
    }

    func save(_ credentials: AppStoreConnectCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        var status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = baseQuery
            item[kSecValueData as String] = data
            item[kSecAttrLabel as String] = "AppLocalizer — App Store Connect API key"
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
