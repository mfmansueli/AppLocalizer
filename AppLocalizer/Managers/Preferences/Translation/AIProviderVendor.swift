//
//  AIProviderVendor.swift
//  AppLocalizer
//

import Foundation

/// The AI providers Settings → Translation offers an API key field for.
enum AIProviderVendor: String, CaseIterable, Identifiable, Codable, Sendable {
    case anthropic
    case openAI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anthropic: "Anthropic"
        case .openAI: "OpenAI"
        }
    }

    /// The `SecretStore` name its API key is kept under.
    var secretName: String { "translation.\(rawValue).apiKey" }
}
