//
//  KeychainItems.swift
//  AppLocalizer
//

import Foundation
import Security

/// The generic-password items of one Keychain service, one per account
/// name. It's the file-based login keychain, not the data-protection one:
/// that one needs a provisioning profile with a keychain access group, which
/// a locally signed tool lacks. The file-based keychain can't return several
/// items' data in one query, so `accounts()` lists the names and
/// `data(for:)` reads one item at a time.
struct KeychainItems: Sendable {
    let service: String
    /// What Keychain Access shows for each item.
    var label: String

    func data(for account: String) throws -> Data? {
        var query = query(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError(status: status) }
        return data
    }

    /// Adds the item, or replaces its data when it's already there.
    func set(_ data: Data, for account: String) throws {
        let query = query(account: account)
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrLabel as String] = label
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    /// Deleting an item that isn't there succeeds.
    func delete(_ account: String) throws {
        let status = SecItemDelete(query(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }

    /// Every account name in the service, oldest item first.
    func accounts() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let attributes = items as? [[String: Any]] else { throw KeychainError(status: status) }
        return attributes
            .compactMap { item -> (account: String, created: Date)? in
                guard let account = item[kSecAttrAccount as String] as? String else { return nil }
                return (account, item[kSecAttrCreationDate as String] as? Date ?? .distantPast)
            }
            // Creation dates only have whole seconds; the name breaks ties.
            .sorted { ($0.created, $0.account) < ($1.created, $1.account) }
            .map(\.account)
    }

    private func query(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
