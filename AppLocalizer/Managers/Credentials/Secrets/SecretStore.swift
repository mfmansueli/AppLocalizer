//
//  SecretStore.swift
//  AppLocalizer
//

import Foundation

/// Small secrets other than App Store Connect keys, such as an AI
/// provider's API key, by name. `KeychainSecretStore` is the real one; DEBUG
/// scenes and tests keep them in memory.
protocol SecretStore {
    func secret(named name: String) throws -> String?
    /// nil removes the secret.
    func setSecret(_ secret: String?, named name: String) throws
}
