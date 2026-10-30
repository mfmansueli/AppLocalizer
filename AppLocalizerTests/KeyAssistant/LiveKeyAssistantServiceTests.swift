//
//  LiveKeyAssistantServiceTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The real service against canned HTTP answers: a rejected key, the
/// models a key can use, and one completion with its tokens.
@Suite("LiveKeyAssistantService")
struct LiveKeyAssistantServiceTests {
    @Test func aRejectedKeySaysSo() async {
        let transport = FakeHTTPTransport([CannedHTTPResponse(statusCode: 401, body: #"{"error":{"message":"invalid x-api-key"}}"#)])
        let service = LiveKeyAssistantService(transport: transport)
        await #expect(throws: KeyAssistantKeyError.rejected(.anthropic, statusCode: 401)) {
            try await service.modelIDs(vendor: .anthropic, apiKey: "sk-ant-wrong")
        }
        #expect(transport.requests.first?.value(forHTTPHeaderField: "x-api-key") == "sk-ant-wrong")
    }

    @Test func theModelsComeFromTheVendorsList() async throws {
        let transport = FakeHTTPTransport([CannedHTTPResponse(body: #"{"data":[{"id":"gpt-5.5"},{"id":"gpt-5.5-mini"}]}"#)])
        let ids = try await LiveKeyAssistantService(transport: transport).modelIDs(vendor: .openAI, apiKey: "sk-proj-test")
        #expect(ids == ["gpt-5.5", "gpt-5.5-mini"])
        #expect(transport.requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer sk-proj-test")
    }

    @Test func aCompletionIsItsTextAndTokens() async throws {
        let transport = FakeHTTPTransport([CannedHTTPResponse(body: """
        {"choices":[{"message":{"role":"assistant","content":" {\\"suggestions\\": []} "},"finish_reason":"stop"}],"usage":{"total_tokens":930}}
        """)])
        let completion = AIProviderCompletion(system: "S", user: "U", model: "gpt-5.5", maxTokens: 100, wantsJSON: true)
        let answer = try await LiveKeyAssistantService(transport: transport).complete(completion, vendor: .openAI, apiKey: "sk-proj-test")
        #expect(answer.text == #"{"suggestions": []}"#)
        #expect(answer.tokens == 930)
        let body = try #require(transport.requests.first?.httpBody).flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        #expect((body?["response_format"] as? [String: Any])?["type"] as? String == "json_object")
    }

    @Test func anEmptyAnswerIsUnreadable() async {
        let transport = FakeHTTPTransport([CannedHTTPResponse(body: #"{"choices":[{"message":{"role":"assistant","content":"  "},"finish_reason":"stop"}]}"#)])
        let completion = AIProviderCompletion(system: "S", user: "U", model: "gpt-5.5", maxTokens: 100)
        await #expect(throws: AIProviderError.unreadableResponse(.openAI)) {
            try await LiveKeyAssistantService(transport: transport).complete(completion, vendor: .openAI, apiKey: "k")
        }
    }
}
