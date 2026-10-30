//
//  AIProviderVendorKeyAssistantTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What setup offers for each provider's key: Claude's three models (only
/// those the key lists), the recommended OpenAI and Gemini model, and how
/// a saved key is named and shown.
@Suite("AIProviderVendor+KeyAssistant")
struct AIProviderVendorKeyAssistantTests {
    @Test func claudeKeysOfferTheModelsTheyListSonnetFirst() {
        let models = AIProviderVendor.anthropic.assistantModels(available: ["claude-haiku-5-5", "claude-sonnet-5-5-20261001", "claude-3-haiku"])
        #expect(models.map(\.id) == ["claude-sonnet-5-5", "claude-haiku-5-5"])
        #expect(models.first?.pickerTitle == "Claude Sonnet 5.5 · recommended")
        #expect(AIProviderVendor.anthropic.assistantModels(available: []).map(\.id) == ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"])
    }

    @Test func openAIKeysGetOneRecommendedModel() {
        #expect(AIProviderVendor.openAI.assistantModels(available: ["gpt-4o", "gpt-5.5", "gpt-5"]).map(\.id) == ["gpt-5.5"])
        #expect(AIProviderVendor.openAI.assistantModels(available: ["whisper-1", "gpt-4o"]).map(\.id) == ["gpt-4o"])
        #expect(AIProviderVendor.openAI.assistantModels(available: []).first?.pickerTitle == "Recommended for your key")
    }

    @Test func geminiPrefersTheNewestStablePro() {
        #expect(AIProviderVendor.recommendedGemini(in: ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-3.0-pro-preview"]) == "gemini-2.5-pro")
        #expect(AIProviderVendor.recommendedGemini(in: ["gemini-2.5-pro", "gemini-3.0-pro"]) == "gemini-3.0-pro")
        #expect(AIProviderVendor.recommendedGemini(in: ["gemini-3.0-pro-preview"]) == "gemini-3.0-pro-preview")
        #expect(AIProviderVendor.recommendedGemini(in: ["gemini-2.5-flash"]) == nil)
        #expect(AIProviderVendor.gemini.assistantModels(available: ["gemini-2.5-flash"]).map(\.id) == [GeminiGenerateAPI.model])
    }

    @Test func theKeyIsKeptApartFromTranslationsAndShownMasked() {
        #expect(AIProviderVendor.anthropic.assistantSecretName == "assistant.anthropic.apiKey")
        #expect(AIProviderVendor.gemini.assistantSecretName != AIProviderVendor.gemini.secretName)
        #expect(AIProviderVendor.gemini.apiName == "Gemini API")
        let configuration = KeyAssistantConfiguration(vendor: .anthropic, model: AIProviderVendor.claudeModels[0], keySuffix: "4f2Q")
        #expect(configuration.maskedKey == "sk-ant-…4f2Q")
    }
}
