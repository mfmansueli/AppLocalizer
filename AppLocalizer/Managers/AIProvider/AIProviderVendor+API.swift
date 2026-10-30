//
//  AIProviderVendor+API.swift
//  AppLocalizer
//

import Foundation

extension AIProviderVendor {
    /// The HTTP API translations go through.
    var api: any AIProviderAPI {
        switch self {
        case .anthropic: AnthropicMessagesAPI()
        case .openAI: OpenAIChatAPI()
        case .gemini: GeminiGenerateAPI()
        }
    }
}
