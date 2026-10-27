//
//  OpenAIChatAPI.swift
//  AppLocalizer
//

import Foundation

/// OpenAI's Chat Completions API (`POST /v1/chat/completions`).
struct OpenAIChatAPI: AIProviderAPI {
    static let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    static let model = "gpt-5.5"

    func request(for prompt: AIProviderTranslationPrompt, apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(Body(
            model: Self.model,
            messages: [Message(role: "system", content: prompt.system), Message(role: "user", content: prompt.user)]
        ))
        return request
    }

    func text(from data: Data) throws -> String {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let choice = (try? decoder.decode(Response.self, from: data))?.choices.first else {
            throw AIProviderError.unreadableResponse(.openAI)
        }
        if choice.message.refusal != nil || choice.finishReason == "content_filter" {
            throw AIProviderError.declined(.openAI)
        }
        if choice.finishReason == "length" { throw AIProviderError.cutOff(.openAI) }
        return choice.message.content ?? ""
    }

    private struct Body: Encodable {
        let model: String
        let messages: [Message]
    }

    private struct Message: Codable {
        let role: String
        let content: String?
        var refusal: String?
    }

    private struct Response: Decodable {
        let choices: [Choice]
    }

    private struct Choice: Decodable {
        let message: Message
        let finishReason: String?
    }
}
