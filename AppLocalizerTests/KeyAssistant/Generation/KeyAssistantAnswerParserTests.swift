//
//  KeyAssistantAnswerParserTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Suggestions out of a model's answer, wrapped or bare, fenced or after a
/// sentence.
@Suite("KeyAssistantAnswerParser")
struct KeyAssistantAnswerParserTests {
    @Test func readsTheWrapperEvenInAFence() throws {
        let text = """
        Here you go:
        ```json
        {"suggestions": [{"locale": "en-US", "field": "subtitle", "value": "Private diary", "reason": "Reviews."}]}
        ```
        """
        let items = try KeyAssistantAnswerParser.items(from: text, vendor: .anthropic)
        #expect(items == [KeyAssistantSuggestionItem(locale: "en-US", field: "subtitle", value: "Private diary", reason: "Reviews.")])
    }

    @Test func readsABareListWithoutReasons() throws {
        let items = try KeyAssistantAnswerParser.items(from: #"[{"locale": "de-DE", "field": "keywords", "value": "tagebuch"}]"#, vendor: .openAI)
        #expect(items.first?.reason == nil)
        #expect(items.count == 1)
    }

    @Test func anythingElseIsUnreadable() throws {
        #expect(throws: AIProviderError.unreadableResponse(.gemini)) {
            try KeyAssistantAnswerParser.items(from: "Sorry, I can’t help.", vendor: .gemini)
        }
        #expect(try KeyAssistantAnswerParser.items(from: #"{"suggestions": []}"#, vendor: .gemini).isEmpty)
    }
}
