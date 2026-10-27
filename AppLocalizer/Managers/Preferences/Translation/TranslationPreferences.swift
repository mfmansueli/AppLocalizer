//
//  TranslationPreferences.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Settings → Translation: the provider, the glossary of terms that are
/// never translated, the source locale and the tone. The AI provider's API
/// key goes to the Keychain (`SecretStore`), never to `UserDefaults`.
@MainActor
@Observable
final class TranslationPreferences {
    var provider: TranslationProvider {
        didSet { defaults?.set(provider.rawValue, forKey: Key.provider) }
    }

    var vendor: AIProviderVendor {
        didSet {
            defaults?.set(vendor.rawValue, forKey: Key.vendor)
            hasAPIKey = Self.hasKey(for: vendor, in: secrets)
        }
    }

    /// Terms and tone, as the Translate sheet uses them.
    var glossary: TranslationGlossary {
        didSet { defaults?.set(try? JSONEncoder().encode(glossary), forKey: Key.glossary) }
    }

    /// The locale translations start from; nil uses each app's primary locale.
    var sourceLocaleCode: String? {
        didSet { defaults?.set(sourceLocaleCode, forKey: Key.sourceLocaleCode) }
    }

    /// Whether the selected vendor's API key is saved.
    private(set) var hasAPIKey: Bool

    private let defaults: UserDefaults?
    private let secrets: any SecretStore

    /// nil `defaults` keeps settings in memory (DEBUG scenes, tests).
    init(defaults: UserDefaults? = .standard, secrets: any SecretStore) {
        self.defaults = defaults
        self.secrets = secrets
        provider = defaults?.string(forKey: Key.provider).flatMap(TranslationProvider.init(rawValue:)) ?? .appleTranslation
        let vendor = defaults?.string(forKey: Key.vendor).flatMap(AIProviderVendor.init(rawValue:)) ?? .anthropic
        self.vendor = vendor
        glossary = defaults?.data(forKey: Key.glossary)
            .flatMap { try? JSONDecoder().decode(TranslationGlossary.self, from: $0) } ?? TranslationGlossary()
        sourceLocaleCode = defaults?.string(forKey: Key.sourceLocaleCode)
        hasAPIKey = Self.hasKey(for: vendor, in: secrets)
    }

    /// Saves the selected vendor's API key in the Keychain; an empty key
    /// removes it.
    func saveAPIKey(_ key: String) throws {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        try secrets.setSecret(key.isEmpty ? nil : key, named: vendor.secretName)
        hasAPIKey = !key.isEmpty
    }

    /// The selected vendor's key, for the code that calls the provider.
    func apiKey() throws -> String? {
        try secrets.secret(named: vendor.secretName)
    }

    private static func hasKey(for vendor: AIProviderVendor, in secrets: any SecretStore) -> Bool {
        ((try? secrets.secret(named: vendor.secretName)) ?? nil) != nil
    }

    private enum Key {
        static let provider = "translationProvider"
        static let vendor = "translationVendor"
        static let glossary = "translationGlossary"
        static let sourceLocaleCode = "translationSourceLocale"
    }
}
