//
//  LiveAIProviderKeyCheckerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Checking an AI provider key against canned HTTP answers: the free
/// request each vendor gets, and what its answer means.
@Suite("LiveAIProviderKeyChecker")
struct LiveAIProviderKeyCheckerTests {
    private static let checkedAt = Date(timeIntervalSince1970: 1_800_000_000)

    private func make(_ responses: [CannedHTTPResponse]) -> (LiveAIProviderKeyChecker, FakeHTTPTransport) {
        let transport = FakeHTTPTransport(responses)
        return (LiveAIProviderKeyChecker(transport: transport, now: { Self.checkedAt }), transport)
    }

    @Test func anthropicIsAskedForTheTranslationModelWithTheKeyAndVersion() async throws {
        let (checker, transport) = make([CannedHTTPResponse(body: #"{"type":"model","id":"claude-opus-5-5"}"#)])
        _ = try await checker.check("sk-ant-test", for: .anthropic)
        let request = try #require(transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/models/claude-opus-5-5")
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-ant-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == AnthropicMessagesAPI.apiVersion)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func openAIIsAskedForTheTranslationModelWithABearerKey() async throws {
        let (checker, transport) = make([CannedHTTPResponse(body: #"{"id":"gpt-5.5","object":"model"}"#)])
        _ = try await checker.check("sk-test", for: .openAI)
        let request = try #require(transport.requests.first)
        #expect(request.url == OpenAIChatAPI.modelsEndpoint.appending(path: OpenAIChatAPI.model))
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == nil)
    }

    @Test func aPassingCheckNamesTheVendorAndWhenItRan() async throws {
        let (checker, _) = make([CannedHTTPResponse(body: "{}")])
        let check = try await checker.check("sk-test", for: .openAI)
        #expect(check.vendor == .openAI)
        #expect(check.date == Self.checkedAt)
        #expect(check.milliseconds >= 0)
    }

    @Test(arguments: [
        (401, AIProviderError.unauthorized(.anthropic)),
        (403, .unauthorized(.anthropic)),
        (429, .rateLimited(.anthropic)),
        (529, .unavailable(.anthropic)),
        (404, .rejected(.anthropic, statusCode: 404, message: "model: claude-opus-5-5")),
    ])
    func aRefusalSaysWhy(statusCode: Int, expected: AIProviderError) async {
        let refusal = CannedHTTPResponse(
            statusCode: statusCode,
            body: #"{"type":"error","error":{"type":"not_found_error","message":"model: claude-opus-5-5"}}"#
        )
        let (checker, _) = make([refusal])
        await #expect(throws: expected) {
            try await checker.check("sk-ant-test", for: .anthropic)
        }
    }

    @Test func anAnswerThatIsntHTTPFails() async {
        let (checker, _) = make([CannedHTTPResponse(body: "", isHTTP: false)])
        await #expect(throws: AIProviderError.unreadableResponse(.openAI)) {
            try await checker.check("sk-test", for: .openAI)
        }
    }
}
