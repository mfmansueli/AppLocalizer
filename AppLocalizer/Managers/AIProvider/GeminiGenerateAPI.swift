//
//  GeminiGenerateAPI.swift
//  AppLocalizer
//

import Foundation

/// Google's Gemini API (`POST /v1beta/models/<model>:generateContent`), with
/// the key in `x-goog-api-key`. A key is checked by listing its models,
/// which needs no particular model.
struct GeminiGenerateAPI: AIProviderAPI {
    static let base = URL(string: "https://generativelanguage.googleapis.com/v1beta")!
    static let model = "gemini-2.5-pro"

    var defaultModel: String { Self.model }

    func request(for completion: AIProviderCompletion, apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: Self.base.appending(path: "models/\(completion.model):generateContent"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(Body(
            systemInstruction: Content(role: nil, parts: [Part(text: completion.system)]),
            contents: [Content(role: "user", parts: [Part(text: completion.user)])],
            generationConfig: GenerationConfig(
                maxOutputTokens: completion.maxTokens,
                responseMimeType: completion.wantsJSON ? "application/json" : nil
            )
        ))
        return request
    }

    func checkRequest(apiKey: String) -> URLRequest {
        modelsRequest(apiKey: apiKey)
    }

    func modelsRequest(apiKey: String) -> URLRequest {
        let url = Self.base.appending(path: "models").appending(queryItems: [URLQueryItem(name: "pageSize", value: "200")])
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        return request
    }

    /// The models that can write text, without the `models/` prefix.
    func modelIDs(from data: Data) throws -> [String] {
        guard let list = try? JSONDecoder().decode(ModelList.self, from: data) else { throw AIProviderError.unreadableResponse(.gemini) }
        return list.models
            .filter { $0.supportedGenerationMethods?.contains("generateContent") ?? true }
            .map { $0.name.hasPrefix("models/") ? String($0.name.dropFirst("models/".count)) : $0.name }
    }

    func text(from data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
            throw AIProviderError.unreadableResponse(.gemini)
        }
        if response.promptFeedback?.blockReason != nil { throw AIProviderError.declined(.gemini) }
        guard let candidate = response.candidates?.first else { throw AIProviderError.unreadableResponse(.gemini) }
        switch candidate.finishReason {
        case "SAFETY", "RECITATION", "BLOCKLIST", "PROHIBITED_CONTENT": throw AIProviderError.declined(.gemini)
        case "MAX_TOKENS": throw AIProviderError.cutOff(.gemini)
        default: break
        }
        // Thought parts are summaries, not the answer.
        return (candidate.content?.parts ?? []).filter { $0.thought != true }.compactMap(\.text).joined()
    }

    func tokenCount(from data: Data) -> Int? {
        (try? JSONDecoder().decode(Response.self, from: data))?.usageMetadata?.totalTokenCount
    }

    private struct Body: Encodable {
        let systemInstruction: Content
        let contents: [Content]
        let generationConfig: GenerationConfig
    }

    private struct Content: Codable {
        let role: String?
        let parts: [Part]
    }

    private struct Part: Codable {
        let text: String?
        var thought: Bool?
    }

    private struct GenerationConfig: Encodable {
        let maxOutputTokens: Int
        let responseMimeType: String?
    }

    private struct Response: Decodable {
        let candidates: [Candidate]?
        let promptFeedback: PromptFeedback?
        let usageMetadata: Usage?
    }

    private struct Candidate: Decodable {
        let content: Content?
        let finishReason: String?
    }

    private struct PromptFeedback: Decodable {
        let blockReason: String?
    }

    private struct Usage: Decodable {
        let totalTokenCount: Int?
    }

    private struct ModelList: Decodable {
        let models: [Model]
    }

    private struct Model: Decodable {
        let name: String
        let supportedGenerationMethods: [String]?
    }
}
