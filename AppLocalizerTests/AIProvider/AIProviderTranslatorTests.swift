//
//  AIProviderTranslatorTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The AI provider's translator against canned HTTP answers: the request
/// each vendor gets, the text read back, and why a field fails.
@Suite("AIProviderTranslator")
struct AIProviderTranslatorTests {
    private func make(_ responses: [CannedHTTPResponse], vendor: AIProviderVendor = .anthropic) -> (AIProviderTranslator, FakeHTTPTransport) {
        let transport = FakeHTTPTransport(responses)
        return (AIProviderTranslator(vendor: vendor, apiKey: "sk-test", tone: .playful, transport: transport), transport)
    }

    private func json(of request: URLRequest?) throws -> [String: Any] {
        let data = try #require(request?.httpBody)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private static let anthropicAnswer = CannedHTTPResponse(body: """
    {"content":[{"type":"thinking","thinking":""},{"type":"text","text":" Lumen : journal \\n"}],"stop_reason":"end_turn"}
    """)

    // MARK: - Anthropic

    @Test func anthropicGetsTheKeyTheVersionAndTheFallbackBeta() async throws {
        let (translator, transport) = make([Self.anthropicAnswer])
        _ = try await translator.translate("Lumen: journal", field: .name, from: .englishUS, to: .french)
        let request = try #require(transport.requests.first)
        #expect(request.url == AnthropicMessagesAPI.endpoint)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2026-10-21")
        #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "server-side-fallback-2026-07-01")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func anthropicBodyCarriesTheModelThePromptAndLowEffort() async throws {
        let (translator, transport) = make([Self.anthropicAnswer])
        _ = try await translator.translate("Lumen: journal", field: .name, from: .englishUS, to: .french)
        let body = try json(of: transport.requests.first)
        #expect(body["model"] as? String == "claude-opus-5-5")
        #expect(body["max_tokens"] as? Int == 16000)
        #expect(body["fallbacks"] as? String == "default")
        #expect((body["output_config"] as? [String: Any])?["effort"] as? String == "low")
        let system = try #require(body["system"] as? String)
        #expect(system.contains("French"))
        #expect(system.contains("Keep the tone playful."))
        #expect(system.contains("It must fit in 30 characters."))
        let messages = try #require(body["messages"] as? [[String: Any]])
        #expect(messages.count == 1)
        #expect(messages.first?["role"] as? String == "user")
        #expect((messages.first?["content"] as? String)?.hasSuffix("\n\nLumen: journal") == true)
    }

    @Test func anthropicAnswerIsItsTextTrimmed() async throws {
        let (translator, _) = make([Self.anthropicAnswer])
        let text = try await translator.translate("Lumen: journal", field: .name, from: .englishUS, to: .french)
        #expect(text == "Lumen : journal")
    }

    @Test func aDeclinedOrCutOffAnswerFails() async {
        let refusal = CannedHTTPResponse(body: #"{"content":[],"stop_reason":"refusal"}"#)
        let cutOff = CannedHTTPResponse(body: #"{"content":[{"type":"text","text":"Lum"}],"stop_reason":"max_tokens"}"#)
        let (translator, _) = make([refusal, cutOff])
        await #expect(throws: AIProviderError.declined(.anthropic)) {
            try await translator.translate("Hi", field: .subtitle, from: .englishUS, to: .german)
        }
        await #expect(throws: AIProviderError.cutOff(.anthropic)) {
            try await translator.translate("Hi", field: .subtitle, from: .englishUS, to: .german)
        }
    }

    // MARK: - OpenAI

    @Test func openAIGetsABearerKeyAndBothMessages() async throws {
        let answer = CannedHTTPResponse(body: #"{"choices":[{"message":{"role":"assistant","content":"Tagebuch,Stimmung"},"finish_reason":"stop"}]}"#)
        let (translator, transport) = make([answer], vendor: .openAI)
        let text = try await translator.translate("diary,mood", field: .keywords, from: .englishUS, to: .german)
        #expect(text == "Tagebuch,Stimmung")
        let request = try #require(transport.requests.first)
        #expect(request.url == OpenAIChatAPI.endpoint)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == nil)
        let body = try json(of: request)
        #expect(body["model"] as? String == OpenAIChatAPI.model)
        let messages = try #require(body["messages"] as? [[String: Any]])
        #expect(messages.map { $0["role"] as? String } == ["system", "user"])
        #expect((messages.first?["content"] as? String)?.contains("It must fit in 100 bytes in UTF-8.") == true)
    }

    @Test func openAIRefusalsAndLengthStopsFail() async {
        let refusal = CannedHTTPResponse(body: #"{"choices":[{"message":{"role":"assistant","content":null,"refusal":"No."},"finish_reason":"stop"}]}"#)
        let length = CannedHTTPResponse(body: #"{"choices":[{"message":{"role":"assistant","content":"Tage"},"finish_reason":"length"}]}"#)
        let (translator, _) = make([refusal, length], vendor: .openAI)
        await #expect(throws: AIProviderError.declined(.openAI)) {
            try await translator.translate("Hi", field: .subtitle, from: .englishUS, to: .german)
        }
        await #expect(throws: AIProviderError.cutOff(.openAI)) {
            try await translator.translate("Hi", field: .subtitle, from: .englishUS, to: .german)
        }
    }

    // MARK: - Failures

    @Test(arguments: [
        (401, AIProviderError.unauthorized(.anthropic)),
        (403, .unauthorized(.anthropic)),
        (429, .rateLimited(.anthropic)),
        (529, .unavailable(.anthropic)),
        (400, .rejected(.anthropic, statusCode: 400, message: "max_tokens: too large")),
    ])
    func httpFailuresSayWhy(statusCode: Int, expected: AIProviderError) async {
        let failure = CannedHTTPResponse(
            statusCode: statusCode,
            body: #"{"type":"error","error":{"type":"invalid_request_error","message":"max_tokens: too large"}}"#
        )
        let (translator, _) = make([failure])
        await #expect(throws: expected) {
            try await translator.translate("Hi", field: .subtitle, from: .englishUS, to: .german)
        }
    }

    @Test func anUnreadableAnswerFails() async {
        let (translator, _) = make([CannedHTTPResponse(body: "<html>")])
        await #expect(throws: AIProviderError.unreadableResponse(.anthropic)) {
            try await translator.translate("Hi", field: .subtitle, from: .englishUS, to: .german)
        }
    }

    @Test func everyLanguageIsAvailable() async {
        let (translator, _) = make([])
        #expect(await translator.availability(from: .englishUS, to: .korean) == .ready)
    }
}
