//
//  AIProviderErrorTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The reasons a failed field shows.
@Suite("AIProviderError")
struct AIProviderErrorTests {
    @Test func messagesNameTheVendor() {
        #expect(AIProviderError.unauthorized(.openAI).errorDescription == "OpenAI rejected the API key. Check it in Settings → Translation.")
        #expect(AIProviderError.rateLimited(.anthropic).errorDescription == "Anthropic’s rate limit was reached. Try again in a minute.")
        #expect(AIProviderError.declined(.anthropic).errorDescription == "Anthropic declined to translate this text.")
    }

    @Test func aRejectionCarriesTheProvidersMessage() {
        let error = AIProviderError(vendor: .openAI, statusCode: 404, body: Data(#"{"error":{"message":"The model does not exist."}}"#.utf8))
        #expect(error == .rejected(.openAI, statusCode: 404, message: "The model does not exist."))
        #expect(error.errorDescription == "OpenAI returned an error (404). The model does not exist.")
    }

    @Test func aRejectionWithoutABodyKeepsTheStatus() {
        let error = AIProviderError(vendor: .anthropic, statusCode: 413, body: Data())
        #expect(error.errorDescription == "Anthropic returned an error (413).")
    }
}
