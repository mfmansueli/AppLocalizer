//
//  TranslationPreferencesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("TranslationPreferences")
struct TranslationPreferencesTests {
    private func defaults() -> UserDefaults {
        let name = "TranslationPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func startsWithAppleTranslationAndAnEmptyGlossary() {
        let preferences = TranslationPreferences(defaults: nil, secrets: InMemorySecretStore())
        #expect(preferences.provider == .appleTranslation)
        #expect(preferences.vendor == .anthropic)
        #expect(preferences.glossary.terms.isEmpty)
        #expect(preferences.glossary.tone == .warmAndSimple)
        #expect(preferences.sourceLocaleCode == nil)
        #expect(!preferences.hasAPIKey)
    }

    @Test func settingsSurviveARelaunch() {
        let defaults = defaults()
        let secrets = InMemorySecretStore()
        let preferences = TranslationPreferences(defaults: defaults, secrets: secrets)
        preferences.provider = .assistant
        preferences.vendor = .openAI
        preferences.glossary.add("Lumen Plus")
        preferences.glossary.tone = .playful
        preferences.sourceLocaleCode = "en-GB"

        let relaunched = TranslationPreferences(defaults: defaults, secrets: secrets)
        #expect(relaunched.provider == .assistant)
        #expect(relaunched.vendor == .openAI)
        #expect(relaunched.glossary.terms == ["Lumen Plus"])
        #expect(relaunched.glossary.tone == .playful)
        #expect(relaunched.sourceLocaleCode == "en-GB")
    }

    @Test func theAIProviderSetupMakesATranslatorOnlyWithAKey() throws {
        let preferences = TranslationPreferences(defaults: nil, secrets: InMemorySecretStore())
        #expect(!preferences.aiProviderSetup().hasKey)
        #expect(preferences.aiProviderSetup().makeTranslator(.neutral) == nil)

        preferences.vendor = .openAI
        try preferences.saveAPIKey("sk-123")
        let setup = preferences.aiProviderSetup()
        #expect(setup.vendor == .openAI)
        #expect(setup.setupMessage == nil)
        let translator = try #require(setup.makeTranslator(.playful) as? AIProviderTranslator)
        #expect(translator.vendor == .openAI)
        #expect(translator.apiKey == "sk-123")
        #expect(translator.tone == .playful)
    }

    @Test func apiKeyGoesToTheSecretStorePerVendor() throws {
        let defaults = defaults()
        let secrets = InMemorySecretStore()
        let preferences = TranslationPreferences(defaults: defaults, secrets: secrets)
        try preferences.saveAPIKey("  sk-ant-123 ")
        #expect(preferences.hasAPIKey)
        #expect(try preferences.apiKey() == "sk-ant-123")
        #expect(try secrets.secret(named: AIProviderVendor.anthropic.secretName) == "sk-ant-123")
        #expect(defaults.dictionaryRepresentation().values.contains { ($0 as? String)?.contains("sk-ant") == true } == false)

        preferences.vendor = .openAI
        #expect(!preferences.hasAPIKey)
        preferences.vendor = .anthropic
        #expect(preferences.hasAPIKey)
    }

    @Test func savingAnEmptyKeyRemovesIt() throws {
        let preferences = TranslationPreferences(defaults: nil, secrets: InMemorySecretStore(secrets: [AIProviderVendor.anthropic.secretName: "old"]))
        #expect(preferences.hasAPIKey)
        try preferences.saveAPIKey("")
        #expect(!preferences.hasAPIKey)
        #expect(try preferences.apiKey() == nil)
    }
}
