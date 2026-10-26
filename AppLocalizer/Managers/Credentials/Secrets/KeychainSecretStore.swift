//
//  KeychainSecretStore.swift
//  AppLocalizer
//

import Foundation

/// Keeps each secret in its own login Keychain item, named by its name.
struct KeychainSecretStore: SecretStore {
    private let items: KeychainItems

    init(service: String = "AppLocalizer.Secrets") {
        items = KeychainItems(service: service, label: "AppLocalizer — API key")
    }

    func secret(named name: String) throws -> String? {
        try items.data(for: name).flatMap { String(bytes: $0, encoding: .utf8) }
    }

    func setSecret(_ secret: String?, named name: String) throws {
        if let secret {
            try items.set(Data(secret.utf8), for: name)
        } else {
            try items.delete(name)
        }
    }
}
