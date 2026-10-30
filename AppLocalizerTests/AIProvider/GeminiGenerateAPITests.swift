//
//  GeminiGenerateAPITests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Google's Gemini API: the request with the key in its header, the text
/// read back without thought summaries, why an answer fails, its models
/// and its token count.
@Suite("GeminiGenerateAPI")
struct GeminiGenerateAPITests {
    private let api = GeminiGenerateAPI()

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let data = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test func theRequestCarriesTheKeyThePromptAndJSON() throws {
        let completion = AIProviderCompletion(system: "You write.", user: "Suggest.", model: "gemini-2.5-pro", maxTokens: 900, wantsJSON: true)
        let request = try api.request(for: completion, apiKey: "AIza-test")
        #expect(request.url?.absoluteString == "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "AIza-test")
        #expect(request.url?.query == nil)
        let body = try json(request)
        let system = try #require(body["systemInstruction"] as? [String: Any])
        #expect((system["parts"] as? [[String: Any]])?.first?["text"] as? String == "You write.")
        let contents = try #require(body["contents"] as? [[String: Any]])
        #expect(contents.first?["role"] as? String == "user")
        #expect((contents.first?["parts"] as? [[String: Any]])?.first?["text"] as? String == "Suggest.")
        let config = try #require(body["generationConfig"] as? [String: Any])
        #expect(config["maxOutputTokens"] as? Int == 900)
        #expect(config["responseMimeType"] as? String == "application/json")
    }

    @Test func theTextLeavesOutThoughts() throws {
        let data = Data(#"""
        {"candidates":[{"content":{"parts":[{"text":"Thinking…","thought":true},{"text":"Private diary"},{"text":", mood"}]},"finishReason":"STOP"}],
         "usageMetadata":{"totalTokenCount":412}}
        """#.utf8)
        #expect(try api.text(from: data) == "Private diary, mood")
        #expect(api.tokenCount(from: data) == 412)
    }

    @Test func blockedAndCutOffAnswersFail() {
        let blocked = Data(#"{"promptFeedback":{"blockReason":"SAFETY"}}"#.utf8)
        #expect(throws: AIProviderError.declined(.gemini)) { try api.text(from: blocked) }
        let safety = Data(#"{"candidates":[{"finishReason":"SAFETY"}]}"#.utf8)
        #expect(throws: AIProviderError.declined(.gemini)) { try api.text(from: safety) }
        let cut = Data(#"{"candidates":[{"content":{"parts":[{"text":"Priv"}]},"finishReason":"MAX_TOKENS"}]}"#.utf8)
        #expect(throws: AIProviderError.cutOff(.gemini)) { try api.text(from: cut) }
        #expect(throws: AIProviderError.unreadableResponse(.gemini)) { try api.text(from: Data("nope".utf8)) }
    }

    @Test func modelsAreThoseThatWriteText() throws {
        let data = Data(#"""
        {"models":[{"name":"models/gemini-2.5-pro","supportedGenerationMethods":["generateContent","countTokens"]},
                   {"name":"models/text-embedding-004","supportedGenerationMethods":["embedContent"]},
                   {"name":"gemini-2.5-flash"}]}
        """#.utf8)
        #expect(try api.modelIDs(from: data) == ["gemini-2.5-pro", "gemini-2.5-flash"])
        let request = api.modelsRequest(apiKey: "AIza-test")
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "AIza-test")
        #expect(request.url?.query == "pageSize=200")
    }
}
