//
//  AIProviderVendor+KeyAssistant.swift
//  AppLocalizer
//

import Foundation

extension AIProviderVendor {
    /// How suggestions made with the key are tagged: "Anthropic API".
    var apiName: String {
        switch self {
        case .anthropic: String(localized: "Anthropic API")
        case .openAI: String(localized: "OpenAI API")
        case .gemini: String(localized: "Gemini API")
        }
    }

    /// What its keys start with, for the field's placeholder and the
    /// masked key: "sk-ant-api03-".
    var keyPrefix: String {
        switch self {
        case .anthropic: "sk-ant-api03-"
        case .openAI: "sk-proj-"
        case .gemini: "AIza"
        }
    }

    /// The page where the person makes a key.
    var keyPageURL: URL {
        switch self {
        case .anthropic: URL(string: "https://console.anthropic.com/settings/keys")!
        case .openAI: URL(string: "https://platform.openai.com/api-keys")!
        case .gemini: URL(string: "https://aistudio.google.com/apikey")!
        }
    }

    /// The assistant's key, kept apart from Settings → Translation's.
    var assistantSecretName: String { "assistant.\(rawValue).apiKey" }

    /// The models setup offers, from the IDs the key can use: Claude
    /// Sonnet, Opus and Haiku 5.5 (all three when the list names none of
    /// them), or the one recommended from an OpenAI or Gemini key's list.
    func assistantModels(available ids: [String]) -> [KeyAssistantModel] {
        switch self {
        case .anthropic:
            let models = Self.claudeModels.filter { model in ids.contains { $0 == model.id || $0.hasPrefix(model.id + "-") } }
            return models.isEmpty ? Self.claudeModels : models
        case .openAI:
            let id = ["gpt-5.5", "gpt-5"].first(where: ids.contains) ?? ids.first { $0.hasPrefix("gpt-") } ?? OpenAIChatAPI.model
            return [Self.recommended(id)]
        case .gemini:
            return [Self.recommended(Self.recommendedGemini(in: ids) ?? GeminiGenerateAPI.model)]
        }
    }

    /// Sonnet first: it's recommended for writing store text.
    static let claudeModels = [
        KeyAssistantModel(id: "claude-sonnet-5-5", name: "Claude Sonnet 5.5", pickerTitle: String(localized: "Claude Sonnet 5.5 · recommended")),
        KeyAssistantModel(id: "claude-opus-5-5", name: "Claude Opus 5.5", pickerTitle: "Claude Opus 5.5"),
        KeyAssistantModel(id: "claude-haiku-5-5", name: "Claude Haiku 5.5", pickerTitle: "Claude Haiku 5.5"),
    ]

    private static func recommended(_ id: String) -> KeyAssistantModel {
        KeyAssistantModel(id: id, name: id, pickerTitle: String(localized: "Recommended for your key"))
    }

    /// The newest `gemini-<version>-pro`, preferring stable ones to
    /// previews.
    static func recommendedGemini(in ids: [String]) -> String? {
        func version(_ id: String) -> Double? {
            let parts = id.split(separator: "-")
            guard parts.count >= 3, parts[0] == "gemini", parts[2] == "pro" else { return nil }
            return Double(parts[1])
        }
        let pros = ids.compactMap { id in version(id).map { (id: id, version: $0, isStable: id.split(separator: "-").count == 3) } }
        return pros.max { ($0.isStable ? 1 : 0, $0.version) < ($1.isStable ? 1 : 0, $1.version) }?.id
    }
}
