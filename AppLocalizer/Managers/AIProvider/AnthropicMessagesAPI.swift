//
//  AnthropicMessagesAPI.swift
//  AppLocalizer
//

import Foundation

/// Anthropic's Messages API (`POST /v1/messages`) with Claude Opus 5.5.
/// Translating a field is a simple task, so it runs at low effort. If a
/// safety classifier declines the request, `fallbacks: "default"` lets
/// Anthropic retry it on the model it recommends, inside the same call.
struct AnthropicMessagesAPI: AIProviderAPI {
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let model = "claude-opus-5-5"
    static let apiVersion = "2026-10-21"
    static let fallbackBeta = "server-side-fallback-2026-07-01"

    func request(for prompt: AIProviderTranslationPrompt, apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue(Self.fallbackBeta, forHTTPHeaderField: "anthropic-beta")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(Body(
            model: Self.model,
            maxTokens: 16000,
            fallbacks: "default",
            outputConfig: OutputConfig(effort: "low"),
            system: prompt.system,
            messages: [Message(role: "user", content: prompt.user)]
        ))
        return request
    }

    func text(from data: Data) throws -> String {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let response = try? decoder.decode(Response.self, from: data) else {
            throw AIProviderError.unreadableResponse(.anthropic)
        }
        switch response.stopReason {
        case "refusal": throw AIProviderError.declined(.anthropic)
        case "max_tokens": throw AIProviderError.cutOff(.anthropic)
        default: break
        }
        // Thinking blocks come back empty; only the text blocks are the answer.
        return response.content.filter { $0.type == "text" }.compactMap(\.text).joined()
    }

    private struct Body: Encodable {
        let model: String
        let maxTokens: Int
        let fallbacks: String
        let outputConfig: OutputConfig
        let system: String
        let messages: [Message]
    }

    private struct OutputConfig: Encodable {
        let effort: String
    }

    private struct Message: Encodable {
        let role: String
        let content: String
    }

    private struct Response: Decodable {
        let content: [Block]
        let stopReason: String?
    }

    private struct Block: Decodable {
        let type: String
        let text: String?
    }
}
