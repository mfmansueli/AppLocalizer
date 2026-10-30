//
//  OpenAIChatAPI.swift
//  AppLocalizer
//

import Foundation

/// OpenAI's Chat Completions API (`POST /v1/chat/completions`).
struct OpenAIChatAPI: AIProviderAPI {
    static let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    static let modelsEndpoint = URL(string: "https://api.openai.com/v1/models")!
    static let model = "gpt-5.5"

    var defaultModel: String { Self.model }

    func request(for completion: AIProviderCompletion, apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(Body(
            model: completion.model,
            messages: [Message(role: "system", content: completion.system), Message(role: "user", content: completion.user)],
            responseFormat: completion.wantsJSON ? ResponseFormat(type: "json_object") : nil
        ))
        return request
    }

    func checkRequest(apiKey: String) -> URLRequest {
        var request = URLRequest(url: Self.modelsEndpoint.appending(path: Self.model), timeoutInterval: 20)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    func modelsRequest(apiKey: String) -> URLRequest {
        var request = URLRequest(url: Self.modelsEndpoint, timeoutInterval: 20)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    func modelIDs(from data: Data) throws -> [String] {
        guard let list = try? JSONDecoder().decode(ModelList.self, from: data) else { throw AIProviderError.unreadableResponse(.openAI) }
        return list.data.map(\.id)
    }

    func tokenCount(from data: Data) -> Int? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decoder.decode(Response.self, from: data))?.usage?.totalTokens
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
        let responseFormat: ResponseFormat?
    }

    private struct ResponseFormat: Encodable {
        let type: String
    }

    private struct Message: Codable {
        let role: String
        let content: String?
        var refusal: String?
    }

    private struct Response: Decodable {
        let choices: [Choice]
        var usage: Usage?
    }

    private struct Usage: Decodable {
        let totalTokens: Int
    }

    private struct ModelList: Decodable {
        let data: [Model]
    }

    private struct Model: Decodable {
        let id: String
    }

    private struct Choice: Decodable {
        let message: Message
        let finishReason: String?
    }
}
