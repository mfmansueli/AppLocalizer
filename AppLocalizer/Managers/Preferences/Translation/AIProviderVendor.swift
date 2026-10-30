//
//  AIProviderVendor.swift
//  AppLocalizer
//

import Foundation

/// The AI providers Settings → Translation offers an API key field for.
enum AIProviderVendor: String, CaseIterable, Identifiable, Codable, Sendable {
    case anthropic
    case openAI
    case gemini

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anthropic: "Anthropic"
        case .openAI: "OpenAI"
        case .gemini: "Google Gemini"
        }
    }

    /// The `SecretStore` name its API key is kept under.
    var secretName: String { "translation.\(rawValue).apiKey" }
}
