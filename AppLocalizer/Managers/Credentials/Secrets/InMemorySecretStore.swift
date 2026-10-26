//
//  InMemorySecretStore.swift
//  AppLocalizer
//

import Foundation

/// A `SecretStore` that forgets everything when the app quits, for DEBUG
/// scenes and tests.
final class InMemorySecretStore: SecretStore {
    private var secrets: [String: String]

    init(secrets: [String: String] = [:]) {
        self.secrets = secrets
    }

    func secret(named name: String) throws -> String? { secrets[name] }
    func setSecret(_ secret: String?, named name: String) throws { secrets[name] = secret }
}
